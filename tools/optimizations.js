const { spawn } = require('child_process');
const { Transform } = require('stream');

const { streamToBuffer } = require('./util');

const TABLES = [
	"draw",
	"math",
	"os",
	"player",
	"render",
	"string",
	"surface",
	"table",
	"TEXFILTER",
	"util",
	"vgui",
];

const GLOBALS = [
	"Angle",
	"CurTime",
	"DrawColorModify",
	"DrawSharpen",
	"FrameTime",
	"GetGlobalBool",
	"GetGlobalFloat",
	"GetGlobalInt",
	"GetGlobalString",
	"ipairs",
	"IsValid",
	"Lerp",
	"LocalPlayer",
	"pairs",
	"rawget",
	"ScrH",
	"ScrW",
	"SysTime",
	"tonumber",
	"tostring",
	"type",
	"Vector",
];

/**
 * Opinionated Lua optimizations. Turbo mode.
 * Incredibly cursed.
 *
 * This relies on a very naive search/replacement technique.
 */
class OptimizationsTransform extends Transform {

	constructor() {
		super({ objectMode: true });

		this.tablesRegExp = {};
		TABLES.forEach((table) => {
			this.tablesRegExp[table] = new RegExp(`([\\s\\(\\)]|^)${table}\\.([A-Za-z_][A-za-z0-9_]+)`, "g");
		});
	}

	/**
	 * Transforms a file.
	 * @param {Object} file The file to process.
	 * @param {string} encoding The encoding of the file.
	 * @param {Function} next A callback function.
	 */
	_transform(file, encoding, next) {
		if (file.isNull()) {
			return next(null, file);
		}

		if (file.isStream()) {
			streamToBuffer(file.contents, (err, contents) => {
				if (err) this.emit('error', err);
				else {
					const code = contents.toString(encoding);
					const optimizedCode = this.optimize(code);
					file.contents = Buffer.from(optimizedCode, encoding);
					next(null, file);
				}
			});
		}

		if (file.isBuffer()) {
			const code = file.contents.toString(encoding);
			const optimizedCode = this.optimize(code);
			file.contents = Buffer.from(optimizedCode, encoding);
			next(null, file);
		}
	}

	optimize(code) {
		const locals = [];

		const memo = new Map();
		const seenTables = new Map();

		// Localize table members. Localized things are marginally faster.
		// The impact is especially noticeable inside rendering hooks.
		TABLES.forEach((table) => {
			const regexp = this.tablesRegExp[table];

			code = code.replace(regexp, (_, whiteSpace, varName) => {
				const newVarName = `${table}_${varName}`;

				// Memoize the variable.
				// We don't need to redeclare it several times.
				if (!memo.has(newVarName)) {
					memo.set(newVarName, true);
					seenTables.set(table, true);

					locals.push(`local ${newVarName} = ${table}.${varName}`);
				}

				return whiteSpace + newVarName;
			});
		});

		// Localize whitelisted globals.
		// Same thing as above really, but slightly different.
		GLOBALS.forEach((global) => {
			if (code.indexOf(global) !== -1) {
				locals.push(`local ${global} = ${global}`);
			}
		})

		if (locals.length > 0) {
			// Prepend seen tables.
			code = Array.from(seenTables.keys())
					.map((table) => `local ${table} = ${table} or {}`)
					.join("\n") + "\n\n" +
				// Prepend the locals.
				locals.join("\n") + "\n\n" + code;
		}

		return code;
	}
}

module.exports = () => new OptimizationsTransform();
module.exports.OptimizationsTransform = OptimizationsTransform;

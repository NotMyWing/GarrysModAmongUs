const { Transform } = require('stream');

const { streamToBuffer } = require('./util');

const LUA_FILE_PREFIX =
`-- !!! THIS FILE IS COMPILED !!!
-- This gamemode is written in Moonscript, and its source code is available
-- here: https://github.com/NotMyWing/GarrysModAmongUs
-- The code you see here is the result of compiled code, and is probably not
-- something you want to edit directly. Please consider editing the original
-- gamemode source off GitHub instead.`;

/**
 * Discourage direct Lua file modification by notifying users where to find
 * the uncompiled gamemode source code.
 */
class DiscourageLuaModificationTransform extends Transform {

	constructor() {
		super({ objectMode: true });
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
					file.contents = Buffer.from(LUA_FILE_PREFIX + '\n\n' + code, encoding);
					next(null, file);
				}
			});
		}

		if (file.isBuffer()) {
			const code = file.contents.toString(encoding);
			file.contents = Buffer.from(LUA_FILE_PREFIX + '\n\n' + code, encoding);
			next(null, file);
		}
	}
}

module.exports = () => new DiscourageLuaModificationTransform();
module.exports.DiscourageLuaModificationTransform = DiscourageLuaModificationTransform;

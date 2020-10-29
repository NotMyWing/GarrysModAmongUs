const { spawn } = require('child_process');
const { Transform } = require('stream');

const { streamToBuffer } = require('./util');

/**
 * Compiles moonscript files to lua using `moonc`.
 */
class MoonscriptTransform extends Transform {

	constructor(compilerPath = "moonc") {
		super({ objectMode: true });
		this.compilerPath = compilerPath;
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
			// Spawn moonc
			const moonc = this.spawnMoonc();

			// Pipe the input
			file.contents.pipe(moonc.stdin);

			// Set the output
			file.extname = ".lua";
			file.contents = moonc.stdout;
			return next(null, file);
		}

		if (file.isBuffer()) {
			// Spawn moonc
			const moonc = this.spawnMoonc();

			// Write the input
			moonc.stdin.write(file.contents);
			moonc.stdin.end();

			// Read the output
			streamToBuffer(moonc.stdout, (err, contents) => {
				if (err) this.emit('error', err);
				else {
					file.extname = ".lua";
					file.contents = contents;
					next(null, file);
				}
			});
		}
	}

	spawnMoonc() {
		// Spawn moonc
		const moonc = spawn(this.compilerPath, ['--'], { windowsHide: true });

		// Connect ChildProcess errors
		moonc.on('error', this.emit.bind(this, 'error'));

		// Connect stderr
		streamToBuffer(moonc.stderr, (err, content) => {
			if (err) this.emit('error', err);
			if (content.length > 0) this.emit('error', new Error(content.toString()));
		});

		return moonc;
	}
}

module.exports = () => new MoonscriptTransform();
module.exports.MoonscriptTransform = MoonscriptTransform;

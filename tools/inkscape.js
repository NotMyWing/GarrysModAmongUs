const { spawn } = require('child_process');
const { Transform } = require('stream');

const { InkscapeIsDumbTransform } = require('./InkscapeIsDumbTransform');
const { streamToBuffer } = require('./util');

/**
 * Renders SVG files using Inkscape.
 */
class InkscapeTransform extends Transform {

	constructor(inkscapePath = "inkscape") {
		super({ objectMode: true });
		this.inkscapePath = inkscapePath;
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
			// Spawn inkscape
			const inkscape = this.spawnInkscape();

			// Pipe the input
			file.contents.pipe(inkscape.stdin);

			// Set the output
			file.extname = ".png";
			file.contents = inkscape.stdout.pipe(new InkscapeIsDumbTransform());
			return next(null, file);
		}

		if (file.isBuffer()) {
			// Spawn inkscape
			const inkscape = this.spawnInkscape();

			// Write the input
			inkscape.stdin.write(file.contents);
			inkscape.stdin.end();

			// Read the output
			const outStream = inkscape.stdout.pipe(new InkscapeIsDumbTransform());
			streamToBuffer(outStream, (err, contents) => {
				if (err) this.emit('error', err);
				else {
					file.extname = ".png";
					file.contents = contents;
					next(null, file);
				}
			});
		}
	}

	spawnInkscape() {
		// Spawn inkscape
		const inkscape = spawn(
			this.inkscapePath,
			['--pipe', '--export-type=png', '--export-filename=-'],
			{ cwd: file.cwd, windowsHide: true }
		);

		// Connect ChildProcess errors
		inkscape.on('error', this.emit.bind(this, 'error'));

		// Connect stderr
		streamToBuffer(inkscape.stderr, (err, content) => {
			if (err) this.emit('error', err);
			if (content.length > 0) this.emit('error', new Error(content.toString()));
		});

		return inkscape;
	}
}

module.exports = () => new InkscapeTransform();
module.exports.InkscapeTransform = InkscapeTransform;

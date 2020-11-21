const { Transform } = require('stream');
const path = require('path');
const { render } = require('resvg-node');

const { streamToBuffer } = require('./util');

/**
 * Renders SVG files using resvg.
 */
class ResvgTransform extends Transform {

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
					const svgData = contents.toString(encoding);
					const pngData = render(svgData, { path: path.dirname(file.path) });
					file.extname = ".png";
					file.contents = pngData;
					next(null, file);
				}
			});
		}

		if (file.isBuffer()) {
			const svgData = file.contents.toString(encoding);
			const pngData = render(svgData, { path: path.dirname(file.path) });
			file.extname = ".png";
			file.contents = pngData;
			next(null, file);
		}
	}
}

module.exports = () => new ResvgTransform();
module.exports.ResvgTransform = ResvgTransform;

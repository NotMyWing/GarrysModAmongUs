const { Transform } = require('stream');
const { streamToBuffer } = require('./util');

function keyValue(data, indents = 0) {
	let str = '';
	const indent = `\t`.repeat(indents);
	const keys = Object.keys(data);
	for (let i = 0; i < keys.length; i++) {
		const key = keys[i]
		switch (typeof data[key]) {
			case 'object':
				str += `${indent}"${key}"\n${indent}{\n${keyValue(data[key], indents +1)}\n${indent}}`;
			break;
			case 'string':
			case 'number':
				str += `${indent}"${key}"\t"${data[key]}"`;
			break;
			case 'boolean':
				str +=`${indent}"${key}"\t"${data[key] ? '1' : '0'}"`;
			break;
		}
		str += i + 1 < keys.length ? '\n' : '';
	}

	return str;
}

/**
 * Transforms a json file into a KeyValue file
 */
class KeyValueTransform extends Transform {

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
					const json = JSON.parse(contents.toString(encoding));
					file.extname = ".txt";
					file.contents = Buffer.from(keyValue(json));
					next(null, file);
				}
			});
		}

		if (file.isBuffer()) {
			const json = JSON.parse(file.contents.toString(encoding));
			file.extname = ".txt";
			file.contents = Buffer.from(keyValue(json));
			next(null, file);
		}
	}
}

module.exports = () => new KeyValueTransform();
module.exports.KeyValueTransform = KeyValueTransform;

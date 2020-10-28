const { Transform } = require('stream');
const luamin = require('luamin');

/**
 * Minifies lua files using luamin.
 */
class LuaminTransform extends Transform {

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
                if(err) this.emit('error', err);
                else {
                    const code = contents.toString(encoding);
                    const minifiedCode = luamin.minify(code);
                    file.contents = Buffer.from(minifiedCode, encoding);
                    next(null, file);
                }
            });
        }

        if (file.isBuffer()) {
            const code = file.contents.toString(encoding);
            const minifiedCode = luamin.minify(code);
            file.contents = Buffer.from(minifiedCode, encoding);
            next(null, file);
        }

    }
}

module.exports = () => new LuaminTransform();
module.exports.LuaminTransform = LuaminTransform;
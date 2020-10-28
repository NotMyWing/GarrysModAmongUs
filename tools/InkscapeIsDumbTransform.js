const { Transform } = require('stream');

const PNG_START_SIGNATURE = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
const PNG_END_SIGNATURE = Buffer.from([73, 69, 78, 68, 239, 191, 189, 66, 96, 239, 191, 189]);

/**
 * Filters out things that aren't a PNG because inkscape is dumb.
 */
class InkscapeIsDumbTransform extends Transform {

	constructor() {
		super();
		// If the PNG has started
		this.started = false;
		// If the PNG has ended
		this.ended = false;
		// The current search byte index
		this.signatureConsumedIndex = 0;
	}

	/**
	 * Searches a chunk for a signature. Note: This uses a per-instance index to
	 * track matches across chunks, so a signature must be completely matched
	 * before searching for another one.
	 * @param {Buffer} chunk The chunk to search.
	 * @param {number} chunkIndex The index to start searching at.
	 * @param {Buffer} signature The signature to search for.
	 */
	_searchChunk(chunk, chunkIndex, signature) {
		// Loop through each byte in the chunk
		for (; chunkIndex < chunk.length; ++chunkIndex) {
			// Check the byte against the next byte in the signature
			if (chunk[chunkIndex] == signature[this.signatureConsumedIndex]) {
				// Consume the byte
				this.signatureConsumedIndex++
				// Check if we've consumed the whole signature
				if (this.signatureConsumedIndex >= signature.length) {
					// Reset the consumed index
					this.signatureConsumedIndex = 0;
					// Return the last index
					return chunkIndex;
				}
			}
			else {
				// Byte doesn't match, so reset the consumed index
				this.signatureConsumedIndex = 0;
			}
		}
		// We reached the end without finding the end of a match
		return -1;
	}

	/**
	 * Transforms a chunk.
	 * @param {Buffer} chunk The chunk to process.
	 * @param {string} encoding The encoding of the chunk.
	 * @param {Function} next A callback function.
	 */
	_transform(chunk, encoding, next) {
		// Start index (inclusive)
		let startIndex = 0;
		// End index (exclusive)
		let endIndex = chunk.length;

		// If we haven't started yet
		if (!this.started) {
			// Look for the start
			const foundIndex = this._searchChunk(chunk, 0, PNG_START_SIGNATURE);
			if (foundIndex !== -1) {
				// Mark as started
				this.started = true;
				// Mark the start index
				startIndex = foundIndex + 1;
				// Write the start
				this.push(PNG_START_SIGNATURE);
			}
		}

		// If we've started but haven't ended yet, look for end
		if (this.started && !this.ended) {

			// Look for the end
			const foundIndex = this._searchChunk(chunk, startIndex, PNG_END_SIGNATURE);
			if (foundIndex !== -1) {
				// Mark as ended
				this.ended = true;
				// Mark the end index
				endIndex = foundIndex + 1;
			}

			// Write everything from <start> to <end>
			if (startIndex !== 0 || endIndex !== chunk.length) {
				this.push(chunk.slice(startIndex, endIndex));
			}
			else {
				this.push(chunk);
			}

		}
		else {
			// We either haven't started or already ended, so ignore the chunk
		}

		// Done processing this chunk
		next();
	}
}

exports.InkscapeIsDumbTransform = InkscapeIsDumbTransform;

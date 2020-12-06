const gulp = require('gulp');
const through = require('through2');
const zip = require('gulp-zip');
const { getLastGitTag, getChangeLog } = require('./util');
const { writeFileSync } = require('fs');

/**
 * Rewrites the version in shared.lua.
 */
function rewriteVersion(cb) {
	return gulp.src('dest/**/shared.lua')
		.pipe(
			through.obj((file, _, callback) => {
				if (file.isBuffer()) {
					var contents = file.contents.toString();

					if (process.env.TRAVIS_BRANCH) {
						contents = contents.replace("{{CI_GAMEMODE_VERSION}}", process.env.TRAVIS_BRANCH);
					}

					if (process.env.WORKSHOP_ID) {
						contents = contents.replace("{{CI_WORSHOP_ID}}", process.env.WORKSHOP_ID);
					}

					file.contents = Buffer.from(contents);
				}
				callback(null, file);
			})
		)
		.pipe(gulp.dest('dest'));
}

/**
 * Zips the dest folder.
 */
function zipGamemode() {
	return gulp.src(['dest/**/*', '!dest/*.zip'])
		.pipe(zip("gamemode.zip"))
		.pipe(gulp.dest('dest'));
}

/**
 * Generates a changelog.
 */
function generateChangeLog(cb) {
	if (process.env.TAGGED_RELEASE == 'true') {
		const tag = getLastGitTag(getLastGitTag());

		if (!tag) {
			cb("Couldn't fetch the last Git tag");
		}

		var changelog = getChangeLog(tag);
		if (!changelog) {
			cb("Couldn't create a changelog")
		}

		if (changelog) {
			changelog = `Changes since ${tag}:\n${changelog}`
		} else {
			changelog = `There have been no changes since ${tag}`
		}

		writeFileSync('dest/changelog.md', changelog);
	}

	cb();
}

module.exports = [
	rewriteVersion,
	zipGamemode,
	generateChangeLog
]

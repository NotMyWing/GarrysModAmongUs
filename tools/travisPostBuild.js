const gulp = require('gulp');
const through = require('through2');
const mustache = require('mustache');
const zip = require('gulp-zip');
const { getLastGitTag, getChangeLog } = require('./util');
const { writeFileSync } = require('fs');

/**
 * Rewrites the version in shared.lua.
 */
function rewriteVersion(cb) {
	const rules = {
		CI_GAMEMODE_VERSION: process.env.TRAVIS_BRANCH,
		CI_WORSHOP_ID      : process.env.WORKSHOP_ID
	};

	return gulp.src('dest/**/shared.lua')
		.pipe(
			through.obj((file, _, callback) => {
				if (file.isBuffer()) {
					const rendered = mustache.render(file.contents.toString(), rules);
					file.contents = Buffer.from(rendered);
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

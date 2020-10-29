const gulp = require('gulp');
const del = require('del');

const renderSvg = require('./tools/inkscape');
const minifyLua = require('./tools/luamin');
const compileMoonscript = require('./tools/moonscript');

/**
 * Cleans the build directories.
 */
function clean() {
	return del(['gamemodes/**/*.lua']);
}
clean.description = "Cleans the build directories.";


/**
 * Minifies lua files and moves them into the gamemodes folder.
 */
function lua() {
	return gulp.src('moon/**/*.lua', { since: gulp.lastRun(lua) })
		.pipe(minifyLua())
		.pipe(gulp.dest('gamemodes'));
}
lua.description = "Minifies lua files and moves them into the gamemodes folder.";


/**
 * Compiles moonscript files and moves them into the gamemodes folder.
 */
function moon() {
	return gulp.src('moon/**/*.moon', { since: gulp.lastRun(moon) })
		.pipe(compileMoonscript())
		// .pipe(minifyLua())
		.pipe(gulp.dest('gamemodes'));
}
moon.description = "Compiles moonscript files and moves them into the gamemodes folder.";


/**
 * Renders SVG assets using inkscape.
 */
function svg() {
	return gulp.src('svg/**/*.svg')
		.pipe(renderSvg())
		.pipe(gulp.dest('gamemodes'));
}
svg.description = "Renders SVG assets using Inkscape.";


/**
 * Builds the gamemode scripts.
 */
const build = gulp.parallel(lua, moon);
build.description = "Builds the gamemode scripts.";


/**
 * Watches lua files and compiles changes.
 */
function watchLua() {
	return gulp.watch(
		['moon/**/*.lua', 'moon/**/*.moon']
		, build
	)
}
build.description = "Watches lua files and compiles changes.";

/**
 * Cleans and builds the project, and then watches files for changes.
 */
const watch = gulp.series(clean, build, watchLua);
watch.description = "Cleans and builds the project, and then watches files for changes.";

exports.clean = clean;
exports.build = build;
exports.watch = watch;
exports.svg = svg;
exports.default = watch;

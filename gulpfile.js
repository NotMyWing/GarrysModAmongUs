const svgmin = require('gulp-svgmin');
const gulp = require('gulp');
const del = require('del');

const renderSvg = require('./tools/inkscape');
const minifyLua = require('./tools/luamin');
const compileMoonscript = require('./tools/moonscript');


/**
 * Cleans the build.
 */
function clean() {
	return del(['gamemodes/**/*.lua', 'gamemodes/amongus/content']);
}
clean.description = "Cleans the build.";


/**
 * Minifies lua files.
 */
function lua() {
	return gulp.src('moon/**/*.lua', { since: gulp.lastRun(lua) })
		.pipe(minifyLua())
		.pipe(gulp.dest('gamemodes'));
}
lua.description = "Minifies lua files.";


/**
 * Compiles moonscript files.
 */
function moon() {
	return gulp.src('moon/**/*.moon', { since: gulp.lastRun(moon) })
		.pipe(compileMoonscript())
		// .pipe(minifyLua())
		.pipe(gulp.dest('gamemodes'));
}
moon.description = "Compiles moonscript files.";


/**
 * Builds the gamemode scripts.
 */
const scripts = gulp.parallel(lua, moon);
scripts.description = "Builds the gamemode scripts.";


/**
 * Watches lua files and compiles changes.
 */
function watchScripts() {
	return gulp.watch(
		['moon/**/*.lua', 'moon/**/*.moon']
		, scripts
	)
}
watchScripts.displayName = "watch-scripts";
watchScripts.description = "Watches lua files and compiles changes.";


/**
 * Renders SVG assets.
 */
function svg() {
	return gulp.src('content/**/*.svg', { since: gulp.lastRun(svg) })
		.pipe(svgmin())
		.pipe(renderSvg())
		.pipe(gulp.dest('gamemodes/amongus/content'));
}
svg.description = "Renders SVG assets.";


/**
 * Copies materials.
 */
function materials() {
	return gulp.src(['content/**/*', '!content/**/*.svg'], { since: gulp.lastRun(materials) })
		.pipe(gulp.dest('gamemodes/amongus/content'));
}
materials.description = "Copies materials.";


/**
 * Generates and moves assets.
 */
const assets = gulp.parallel(materials, svg);
assets.description = "Generates and copies assets.";


/**
 * Watches lua files and compiles changes.
 */
function watchAssets() {
	return gulp.watch(
		['content/**/*']
		, assets
	)
}
watchAssets.displayName = "watch-assets";
watchAssets.description = "Watches assets.";


/**
 * Builds everything.
 */
const build = gulp.parallel(scripts, assets);
build.description = "Builds everything.";


/**
 * Cleans and builds the project, and then watches files for changes.
 */
const watch = gulp.series(clean, build, gulp.parallel(watchAssets, watchScripts));
watch.description = "Cleans and builds the project, and then watches files for changes.";


exports.clean = clean;
exports.svg = svg;
exports.materials = materials;
exports.assets = assets;
exports.watchAssets = watchAssets;
exports.lua = lua;
exports.moon = moon;
exports.scripts = scripts;
exports.watchScripts = watchScripts;
exports.build = build;
exports.watch = watch;
exports.default = watch;

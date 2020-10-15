const { src, dest, task, series } = require('gulp');
const { spawn } = require('child_process');
const through2 = require('through2');
const luamin = require('luamin');
const del = require('del');
const gulp = require('gulp');

const _compileMoonScript = () => through2.obj((file, _, cb) => {
	if (file.isBuffer()) {
		const moonc = spawn('moonc', ['--']);

		let stdout = '';
		let stderr = '';

		const code = file.contents.toString();
		const lines = code.split(/\r?\n/);
		let header = '';
		for (const line of lines) {
			if (line != '' && !line.startsWith('--')) break;
			header += line + '\n';
		}

		moonc.stdin.write(code);
		moonc.stdin.end();

		moonc.stdout.on('data', data => { stdout += data; });
		moonc.stderr.on('data', data => { stderr += data; });
		moonc.on('close', () => {
			if (stderr) cb(stderr);
			else {
				file.path = file.path.substr(0, file.path.lastIndexOf('.')) + '.lua';
				// file.contents = Buffer.from(header + luamin.minify(stdout));
				file.contents = Buffer.from(header + stdout);
				cb(null, file);
			}
		});
	}
});

const _moveLuaFiles = () => through2.obj((file, _, cb) => {
	if (file.isBuffer()) {
		const code = file.contents.toString();
		const lines = code.split(/\r?\n/);
		let header = '';
		for (const line of lines) {
			if (line != '' && !line.startsWith('--')) break;
			header += line + '\n';
		}

		file.contents = Buffer.from(header + luamin.minify(file.contents.toString()));
		file.path = file.path.substr(0, file.path.lastIndexOf('.')) + '.lua';
		cb(null, file);
	}
});

function rmrf(cb) {
	del(['gamemodes/**/*.lua', 'gamemodes/**/*.moon']).then(() => {
		cb();
	});
}

function lua() {
	return src('moon/**/*.lua')
		.pipe(_moveLuaFiles())
		.pipe(dest('gamemodes'));
}

function moon() {
	return src('moon/**/*.moon')
		.pipe(_compileMoonScript())
		.pipe(dest('gamemodes'));
}

const build = gulp.series(lua, moon);

function _watch() {
	return gulp.watch(
		['moon/**/*.lua', 'moon/**/*.moon']
		, build
	)
}

function watch() {
	return gulp.series(
		build
		, _watch
	)()
}

exports.build = build;
exports.watch = watch;
exports.default = watch;
module.exports = function(gulp, config, server) {
	'use strict';

	const sourcemaps = require('gulp-sourcemaps'),
				uglify = require('gulp-uglify'),
				ts = require('gulp-typescript');

	let tsProject = ts.createProject('tsconfig.json', {
		rootDir: 'angular',
		typescript: require('typescript')
	});

	gulp.task('typescript:dev', () => {
		let tsResult =  tsProject.src('angular/**/*.ts')
					.pipe(sourcemaps.init())
	        .pipe(ts(tsProject));

		return tsResult.js
			.pipe(sourcemaps.write())
			.pipe(gulp.dest('build'));
	});

	gulp.task('typescript:prod', () => {
		let tsResult =  tsProject.src('angular/**/*.ts')
					.pipe(sourcemaps.init())
					.pipe(ts(tsProject));

		return tsResult.js
			// .pipe(uglify({
			// 	mangle: false
			// }))
			.pipe(sourcemaps.write())
			.pipe(gulp.dest('build'));
	});

	gulp.task('javascript:dev', () => {
		return gulp.src(['angular/**/*.js'])
			.pipe(gulp.dest('build'));
	});

	gulp.task('javascript:prod', () => {
		return gulp.src(['angular/**/*.js'])
			.pipe(uglify({
				mangle: false
			}))
			.pipe(gulp.dest('build'));
	});

	gulp.task('scripts:dev', gulp.parallel('typescript:dev', 'javascript:dev'));
	gulp.task('scripts:prod', gulp.parallel('typescript:prod', 'javascript:prod'));

	gulp.task('watch:scripts', () => {
		gulp.watch('angular/**/*.ts', gulp.series('typescript:dev'));
		gulp.watch(['angular/**/*.js', 'angular/systemjs.config.js'], gulp.series('javascript:dev'));
	});
}

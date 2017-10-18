module.exports = function(gulp, config) {
	'use strict';

	const sourcemaps = require('gulp-sourcemaps'),
			sass = require('gulp-sass');

	gulp.task('sass:dev', () => {
		return gulp.src(['angular/**/*.scss'])
			.pipe(sourcemaps.init())
	    .pipe(sass().on('error', sass.logError))
			.pipe(sourcemaps.write())
	    .pipe(gulp.dest('build'));
	});

	gulp.task('sass:prod', () => {
		return gulp.src(['angular/**/*.scss'])
	    .pipe(sass({
				outputStyle: 'compressed'
			}).on('error', sass.logError))
	    .pipe(gulp.dest('build'));
	});

	gulp.task('css:dev', () => {
		return gulp.src(['angular/**/*.css'])
			.pipe(gulp.dest('build'));
	});

	gulp.task('css:prod', () => {
		return gulp.src(['angular/**/*.css'])
			.pipe(gulp.dest('build'));
	});

	gulp.task('styles:dev', gulp.parallel('sass:dev', 'css:dev'));
	gulp.task('styles:prod', gulp.parallel('sass:prod', 'css:prod'));

	gulp.task('watch:styles', () => {
		gulp.watch('angular/**/*.scss', gulp.series('sass:dev'));
		gulp.watch('angular/**/*.css', gulp.series('css:dev'));
	});
}

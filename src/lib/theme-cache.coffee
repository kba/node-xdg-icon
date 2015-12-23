Fs           = require 'fs'
Path         = require 'path'
Async        = require 'async'
EventEmitter = require('events').EventEmitter
ParseIndexTheme = require './theme-parser'

{ICON_THEME_DIRS, ICON_DIRS} = require './dirs'

log = require('./log')(module)

module.exports = class ThemeCache extends EventEmitter

	fallbackCache: {}
	themeCache: {}
	indexThemeCache: {}

	constructor: ->

	_getIndexTheme: (themeName, cb) ->
		if @indexThemeCache[themeName]
			return cb null, @indexThemeCache[themeName]
		candidates = (Path.join(dir, themeName, 'index.theme') for dir in ICON_THEME_DIRS)
		Async.detect candidates, Fs.exists, (indexTheme) =>
			return cb "No 'index.theme' was found for #{themeName}" unless indexTheme
			@indexThemeCache[themeName] = indexTheme
			return cb null, indexTheme

	_refreshFallbackIcons: (cb) ->
		Async.each ICON_DIRS, (basedir, doneBasedir) =>
			Fs.readdir basedir, (err, files) =>
				Async.each files, (file, doneFile) =>
					@fallbackCache[file] = Path.join(basedir, file)
					doneFile()
				, => doneBasedir()
		, => cb()


	_refreshThemeIcons: (theme, cb) ->
		Async.each ICON_THEME_DIRS, (basedir, doneBasedir) =>
			Async.each theme.directories, (directory, doneSubdir) =>
				subdirPath = Path.join(basedir, theme.id, directory.id)
				Fs.readdir subdirPath, (err, files) =>
					if files
						log.debug "Adding #{files.length} icons to #{theme.id}/#{directory.id}"
						directory.files[file] = Path.join(subdirPath, file) for file in files
					return doneSubdir()
			, -> doneBasedir()
		, -> cb()

	_findInstalledThemes : (cb) ->
		themes = {}
		Async.each ICON_THEME_DIRS, (basedir, doneBasedir) ->
			Fs.readdir basedir, (err, files) ->
				Async.each files, (file, doneThemeDir) ->
					fullPath = Path.join(basedir, file)
					Fs.stat fullPath, (err, lstat) ->
						if lstat.isDirectory()
							themes[file] = 1
						doneThemeDir()
				, -> doneBasedir()
		, -> cb Object.keys(themes)

	init : () ->
		@_findInstalledThemes (themes) =>
			Async.each themes, (themeName, done) =>
				log.debug "Loading #{themeName}"
				@get themeName, (err) =>
					log.warn(err) if err
					done()
			, (err) =>
				@_refreshFallbackIcons () =>
					@emit 'loaded'

	put: (themeName, theme, cb) ->
		@themeCache[themeName] = theme
		cb null, theme

	get: (themeName, cb) ->
		log.info "GET #{themeName}"
		if themeName of @themeCache
			return cb null, @themeCache[themeName]
		else
			@_getIndexTheme themeName, (err, indexTheme) =>
				return cb err if err
				theme = {id: themeName, 'index.theme': indexTheme}
				ParseIndexTheme indexTheme, theme, (err) =>
					return cb "Problem parsing #{@indexTheme}: #{err}" if err
					@_refreshThemeIcons theme, =>
						@put themeName, theme, cb

	getFallbackIcon: (file, cb) =>
		if @fallbackCache[file]
			return cb null, @fallbackCache[file]
		return cb "Not in fallbackCache: #{file}"

	keys: () ->
		return Object.keys @themeCache

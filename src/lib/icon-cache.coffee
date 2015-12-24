Fs           = require 'fs'
Path         = require 'path'
Async        = require 'async'
EventEmitter = require('events').EventEmitter

log = require('./log')(module)
ParseIndexTheme = require './icon-theme-parser'
IconThemeValidator = require './icon-theme-validator'

module.exports = class ThemeCache extends EventEmitter

	fullRebuildLock : null

	fallbackCache : {}
	themeCache : {}

	constructor: (@config) ->

	_getIndexTheme: (themeName, cb) ->
		candidates = (Path.join(dir, themeName, 'index.theme') for dir in @config.iconThemeDirs)
		Async.detect candidates, Fs.exists, (indexTheme) =>
			return cb "No 'index.theme' was found for #{themeName}" unless indexTheme
			return cb null, indexTheme

	_refreshFallbackIconDir : (basedir, cb) ->
		log.silly "Refresh fallback dir #{basedir}"
		if @fallbackCache[basedir]
			now = new Date()
			cached = @fallbackCache[basedir]
			if now - cached.lastChecked <= @config.cacheTime
				log.silly "Must not check fallback dir #{basedir} yet"
				return cb()
			log.debug "Must check mtime for '#{basedir}', #{now - cached.lastChecked}"
			Fs.stat basedir, (err, stat) =>
				if (err and cached.exists) or
				(not err and stat.mtime isnt cached.mtime)
					return @removeFallbackDir basedir, =>
						@_refreshFallbackIconDir basedir, cb
				cached.lastChecked = new Date()
				return cb()
		else
			cached = @fallbackCache[basedir] or= {
				_cache: {}
			}
			Fs.stat basedir, (err, dirStat) =>
				cached.exists = not err
				cached.lastChecked = new Date()
				return cb() if err
				cached.mtime = dirStat.mtime
				Fs.readdir basedir, (err, files) =>
					Async.each files, (file, doneFile) =>
						fullPath = Path.join(basedir, file)
						Fs.stat fullPath, (err, fileStat) =>
							return doneFile() if err
							if fileStat.isFile()
								cached._cache[file] = fullPath
							doneFile()
					, =>
						log.debug "Cached #{Object.keys(cached._cache).length} files in #{basedir}"
						cb()

	_refreshFallbackIcons: (cb) ->
		log.silly "Refreshing all fallback icons"
		Async.each @config.iconDirs, (basedir, doneBasedir) =>
			@_refreshFallbackIconDir basedir, doneBasedir
		, cb

	_refreshThemeIcons: (theme, cb) ->
		Async.each @config.iconThemeDirs, (basedir, doneBasedir) =>
			themeDir = Path.join(basedir, theme.id)
			Fs.stat themeDir, (err, dirStat) =>
				return doneBasedir() if err
				theme.mtime = new Date(Math.max(theme.mtime, dirStat.mtime))
				Async.eachLimit theme.Directories, 5, (directory, doneSubdir) =>
					subdirPath = Path.join(themeDir, directory.id)
					Fs.readdir subdirPath, (err, files) =>
						if files
							log.silly "Adding #{files.length} icons to #{theme.id}/#{directory.id}"
							directory._cache[file] = Path.join(subdirPath, file) for file in files
						doneSubdir()
				, () =>
					theme.baseDirs or= {}
					theme.baseDirs[basedir] = dirStat.mtime
					doneBasedir()
		, () =>
			theme.lastChecked = new Date()
			cb()

	_findInstalledThemes : (cb) ->
		themes = {}
		Async.each @config.iconThemeDirs, (basedir, doneBasedir) ->
			Fs.readdir basedir, (err, files) ->
				Async.each files, (file, doneThemeDir) ->
					fullPath = Path.join(basedir, file)
					Fs.stat fullPath, (err, lstat) ->
						if lstat.isDirectory()
							themes[file] = 1
						doneThemeDir()
				, -> doneBasedir()
		, -> cb Object.keys(themes)

	rebuild: () ->
		if @fullRebuildLock
			return @emit 'error', "Cache is unavailable due to reindexing since #{@fullRebuildLock}"
		@fullRebuildLock = new Date()
		@clearThemes()
		@clearFallbackIcons()
		@_findInstalledThemes (themes) =>
			Async.each themes, (themeName, done) =>
				log.silly "Loading #{themeName}"
				@getTheme themeName, (err) =>
					log.warn(err) if err
					done()
			, (err) =>
				log.error err if err
				@_refreshFallbackIcons () =>
					@fullRebuildLock = false
					@emit 'rebuilt'

	clearThemeCache : (cb) ->
		Async.each @themeNames, (themeName, doneRemove) =>
			@removeTheme themeName, doneRemove
		, cb

	clearFallbackCache : (cb) ->
		Async.each @fallbackCache, (fallbackDir, doneRemove) =>
			@removeFallbackDir @fallbackCache[fallbackDir], doneRemove
		, cb

	removeTheme : (themeName, cb) ->
		log.debug "Remove theme #{themeName}"
		delete @themeCache[themeName]
		cb null

	removeFallbackDir : (fallbackDir, cb) ->
		log.debug "Remove fallback dir '#{fallbackDir}'"
		delete @fallbackCache[fallbackDir]
		cb null

	getTheme: (themeName, cb) ->
		log.debug "GET-THEME #{themeName}"
		if themeName of @themeCache
			log.silly "#{themeName} is in themeCache"
			now = new Date()
			cached = @themeCache[themeName]
			if now - cached.lastChecked <= @config.cacheTime
				log.silly "Must not check yet"
				return cb null, cached
			log.debug "Must check mtime for theme #{themeName} (#{now - cached.lastChecked}ms ago"
			Async.forEachOf cached.baseDirs, (mtime, dir, done) =>
				Fs.stat dir, (err, stat) =>
					if err or stat.mtime >= cached.mtime
						log.debug 'Directory changed'
						return done 'Must reload theme'
					return done()
			, (needsReload) =>
				cached.lastChecked = new Date()
				return cb null, cached if not needsReload
				log.debug ("Out of date: #{themeName}")
				return @removeTheme themeName, =>
					return @getTheme themeName, cb
		else
			log.debug "#{themeName} is NOT cached"
			@_getIndexTheme themeName, (err, indexTheme) =>
				return cb err if err
				theme = @themeCache[themeName] = {
					id: themeName
					mtime: 0
					'index.theme': indexTheme
				}
				if @config.cacheProfiling
					now = Date.now()
					profileParse = "Parsing #{theme.id} #{now}"
					profileValidate = "Validating #{theme.id} #{now}"
					profileRefresh = "Refreshing #{theme.id} #{now}"
				log.start(profileParse) if @config.cacheProfiling
				ParseIndexTheme indexTheme, theme, (err) =>
					log.logstop(profileParse) if @config.cacheProfiling
					return cb "Problem parsing #{indexTheme}: #{err}" if err
					if @config.validateThemes
						log.start(profileValidate) if @config.cacheProfiling
						result = IconThemeValidator.validate theme
						log.logstop(profileValidate) if @config.cacheProfiling
						if not result.valid
							return cb "Theme #{theme.id} is invalid: #{result.error}"
					log.start(profileRefresh) if @config.cacheProfiling
					@_refreshThemeIcons theme, =>
						log.logstop(profileRefresh) if @config.cacheProfiling
						cb null, theme

	getFallbackIcon: (file, cb) =>
		log.debug "GET-ICON #{file}"
		@_refreshFallbackIcons =>
			Async.detect @config.iconDirs, (basedir, found) =>
				found @fallbackCache[basedir]._cache[file]
			, (firstDir) =>
				return cb null, @fallbackCache[firstDir]._cache[file] if firstDir
				return cb "Not in fallbackCache: #{file}"

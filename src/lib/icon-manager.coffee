Async        = require 'async'
Fs           = require 'fs'
Path         = require 'path'
EventEmitter = require('events').EventEmitter

log        = require('./log')(module)
IconCache  = require './icon-cache'
IconConfig = require './icon-config'

module.exports = class IconManager extends EventEmitter

	constructor: (config={}) ->
		@config = new IconConfig(config)
		@cache = new IconCache(@config)
		@cache.on 'error', (err) =>
			log.error err
			@emit 'error', err
		@cache.once 'rebuilt', =>
			@initialized = true
			@emit 'loaded'

	init : ->
		@cache.rebuild()

	listThemes : (cb) ->
		if @cache.fullRebuildLock
			return cb "Cache is unavailable due to reindexing since #{@cache.fullRebuildLock}"
		return cb null, Object.keys @cache.themeCache

	getTheme : (themeName, cb) ->
		if @cache.fullRebuildLock
			return cb "Cache is unavailable due to reindexing since #{@cache.fullRebuildLock}"
		return @cache.getTheme themeName, cb

	findIcon : (icon, size, themeName, cb) ->
		if @cache.fullRebuildLock
			return cb "Cache is unavailable due to reindexing since #{@cache.fullRebuildLock}"
		[themeName, cb] = [@config.fallbackTheme, themeName] unless cb
		@cache.getTheme themeName, (err, theme) =>
			return cb err if err
			@_findIconHelper icon, size, theme, (err, filename) =>
				return cb null, filename if filename
				log.silly "Failed to find in theme or inherited. Trying fallback theme"
				@cache.getTheme @config.fallbackTheme, (err, fallbackTheme) =>
					@_findIconHelper icon, size, fallbackTheme, (err, filename) =>
						return cb null, filename if filename
						@_lookupFallbackIcon icon, cb

	_findIconHelper: (icon, size, theme, cb) ->
		log.silly "enter#_findIconHelper #{icon} #{size} #{theme.id}"
		@_lookupIcon icon, size, theme, (err, filename) =>
			return cb null, filename if filename
			Async.each theme.Inherits, (parentName, found) =>
				@cache.getTheme parentName, (err, parent) =>
					@_findIconHelper icon, size, parent, (err, filename) =>
						return found filename if filename
						return found false
			, (filename) =>
				return cb null, filename if filename
				return cb "failed#_findIconHelper #{icon} #{size} #{theme.id}"


	findBestIcon: (iconList, size, themeName, cb) ->
		log.debug "enter#findBestIcon #{iconList} #{size} #{themeName}"
		[themeName, cb] = [@config.fallbackTheme, themeName] unless cb
		@cache.getTheme themeName, (err, theme) =>
			@_findBestIconHelper iconList, size, theme, (err, filename) =>
				return cb null, filename if filename
				@cache.getTheme @config.fallbackTheme, (err, fallbackTheme) =>
					@_findBestIconHelper iconList, size, fallbackTheme, (err, filename) =>
						return cb null, filename if filename
						Async.eachSeries iconList, (icon, done) =>
							@_lookupFallbackIcon icon, (err, filename) =>
								return done filename if filename
								return done()
						, (filename) =>
							return cb filename if filename
							return cb 'None of the icons found'

	_findBestIconHelper: (iconList, size, theme, cb) ->
		log.debug "enter#_findBestIconHelper #{iconList} #{size} #{theme.id}"
		Async.eachSeries iconList, (icon, doneIconList) =>
			@_lookupIcon icon, size, theme, (err, filename) =>
				return doneIconList filename if filename
				Async.each theme.Inherits, (parentName, doneParent) =>
					@cache.getTheme parentName, (err, parent) =>
						log.debug "ERRRR ", err
						@_findBestIconHelper iconList, size, parent, (err, filename) =>
							return doneParent filename if filename
							return doneParent false
				, (filename) =>
					return doneIconList filename if filename
					return doneIconList null, "failed#_findBestIconHelper #{icon} #{size} #{theme.id}"
		, (filename, err) =>
			return cb null, filename if filename
			return cb err

	_lookupFallbackIcon: (icon, cb) ->
		log.silly "enter#_lookupFallbackIcon #{icon}"
		Async.each @config.extensions, (extension, found) =>
			@cache.getFallbackIcon "#{icon}.#{extension}", (err, filename) ->
				return found filename if filename
				return found false
		, (filename) ->
			return cb null, filename if filename
			return cb "failed#_lookupFallbackIcon #{icon}"

	_lookupIcon : (iconname, size, theme, cb) ->
		log.silly "enter#_lookupIcon #{iconname} #{size} #{theme.id}"
		for subdir in theme.Directories
			if @_directoryMatchesSize(subdir, size)
				for extension in @config.extensions
					filename = "#{iconname}.#{extension}"
					if subdir._cache[filename]
						log.silly "Found exact match hit in #{theme.id}/#{subdir.id}"
						return cb null, subdir._cache[filename]
		log.silly "No size match for #{iconname} #{size} #{theme.id}"
		minimal_size = Number.MAX_VALUE
		closest_filename = null
		for subdir in theme.Directories
			for extension in @config.extensions
				filename = "#{iconname}.#{extension}"
				subdirDistance = @_directorySizeDistance(subdir, size)
				if subdir._cache[filename] and subdirDistance < minimal_size
					closest_filename = subdir._cache[filename]
					minimal_size = subdirDistance
		if closest_filename
			log.silly "Found with size difference #{minimal_size}: #{closest_filename}"
			return cb null, closest_filename
		return cb "failed#_lookupIcon #{iconname} #{size} #{theme.id}"

	_directoryMatchesSize: (subdir, iconsize) ->
		if subdir.Type is 'Fixed'
			return subdir.Size == iconsize
		if subdir.Type is 'Scalable'
			return subdir.MinSize <= iconsize <= subdir.MaxSize
		if subdir.Type is 'Threshold'
			return subdir.Type - subdir.Threshold <= iconsize <= subdir.Size + subdir.Threshold

	_directorySizeDistance: (subdir, iconsize) ->
		if subdir.Type is 'Fixed'
			return Math.abs(subdir.Size - iconsize)
		if subdir.Type is 'Scalable'
			if iconsize < subdir.MinSize
				return subdir.MinSize - iconsize
			if iconsize > subdir.MaxSize
				return iconsize - subdir.MaxSize
			return 0
		if subdir.Type is 'Threshold'
			if iconsize < subdir.Size - subdir.Threshold
				return subdir.MinSize - iconsize
			if iconsize > subdir.Size + subdir.Threshold
				return iconsize - subdir.MaxSize
			return 0

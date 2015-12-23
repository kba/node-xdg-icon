{ICON_THEME_DIRS, ICON_DIRS, FALLBACK_ICON_THEME} = require './dirs'

Async        = require 'async'
Fs           = require 'fs'
Path         = require 'path'
ThemeCache   = require './theme-cache'
EventEmitter = require('events').EventEmitter

log = require('./log')(module)

class IconManager extends EventEmitter

	constructor: ->
		@cache = new ThemeCache()
		@cache.on 'error', (err) => @emit 'error', err
		@cache.on 'loaded', => @emit 'loaded'
	
	init : ->
		@cache.init()

	listInstalledThemes : () ->
		return @cache.keys()

	findIcon : (icon, size, themeName, cb) ->
		[themeName, cb] = [FALLBACK_ICON_THEME, themeName] unless cb
		@cache.get themeName, (err, themeName) =>
			return cb err if err
			@findIconHelper icon, size, themeName, (err, filename) =>
				log.error err if err
				return cb null, filename if filename
				@cache.get FALLBACK_ICON_THEME, (err, fallbackTheme) =>
					@findIconHelper icon, size, fallbackTheme, (err, filename) =>
						log.error err if err
						return cb null, filename if filename
						@cache.getFallbackIcon icon, cb

	findIconHelper: (icon, size, theme, cb) ->
		log.debug "enter#findIconHelper #{icon}, #{size}, #{theme.id}"
		@lookupIcon icon, size, theme, (err, filename) =>
			log.error err if err
			return cb null, filename if filename
			Async.detect theme.inherits, (parentName, found) =>
				@cache.get parentName, (err, parent) =>
					@findIconHelper icon, size, parent, (err, filename) =>
						return found true if filename
						found()
			, (filename) =>
				return cb null, filename if filename
				return cb "Finally found nothing :("

	lookupIcon : (iconname, size, theme, cb) ->
		log.debug "enter#lookupIcon #{iconname}, #{size}, #{theme.id}"
		for subdir in theme.directories
			if @directoryMatchesSize(subdir, size)
				for extension in ["png", "svg", "xpm"]
					filename = "#{iconname}.#{extension}"
					if subdir.files[filename]
						return cb null, subdir.files[filename]
		log.debug 'lookupIcon: No exact match.'
		minimal_size = Number.MAX_VALUE
		closest_filename = null
		for subdir in theme.directories
			for extension in ["png", "svg", "xpm"]
				filename = "#{iconname}.#{extension}"
				subdirDistance = @directorySizeDistance(subdir, size)
				# log.debug subdir.files
				# log.debug theme.id, subdir.id
				if subdir.files[filename] and subdirDistance < minimal_size
					closest_filename = subdir.files[filename]
					minimal_size = subdirDistance
		if closest_filename
			log.debug "Minimal size: #{minimal_size}: #{closest_filename}"
			return cb null, closest_filename
		return cb "nothing found in lookupIcon"

	directoryMatchesSize: (subdir, iconsize) ->
		if subdir.type is 'Fixed'
			return subdir.size == iconsize
		if subdir.type is 'Scalable'
			return subdir.minSize <= iconsize <= subdir.maxSize
		if subdir.type is 'Threshold'
			return subdir.type - subdir.threshold <= iconsize <= subdir.size + subdir.threshold

	directorySizeDistance: (subdir, iconsize) ->
		if subdir.type is 'Fixed'
			return Math.abs(subdir.size - iconsize)
		if subdir.type is 'Scalable'
			if iconsize < subdir.minSize
				return subdir.minSize - iconsize
			if iconsize > subdir.maxSize
				return iconsize - subdir.maxSize
			return 0
		if subdir.type is 'Threshold'
			if iconsize < subdir.size - subdir.threshold
				return subdir.minSize - iconsize
			if iconsize > subdir.size + subdir.threshold
				return iconsize - subdir.maxSize
			return 0

module.exports = new IconManager()

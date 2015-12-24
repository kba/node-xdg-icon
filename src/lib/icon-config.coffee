{
	ICON_THEME_DIRS
	ICON_DIRS
	ICON_FALLBACK_THEME
	ICON_EXTENSIONS
	ICON_DEFAULT_CACHE_TIME
} = require './icon-constants'

module.exports = class IconConfig

	constructor: (config) ->
		@fallbackTheme = ICON_FALLBACK_THEME
		@iconDirs = ICON_DIRS
		@iconThemeDirs = ICON_THEME_DIRS
		@cacheTime = ICON_DEFAULT_CACHE_TIME
		@extensions = ICON_EXTENSIONS
		@logLevel = 'debug'
		@cacheProfiling = true
		@validateThemes = true
		for k of @
			if k of config
				@[k] = config[k]
		if config.additionalIconDirs
			@iconDirs.unshift v for v in config.additionalIconDirs
		if config.additionalIconThemeDirs
			@iconThemeDirs.unshift v for v in config.additionalIconThemeDirs

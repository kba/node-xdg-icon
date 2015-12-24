XdgBasedir = require 'xdg-basedir'
Path = require 'path'

ICON_DEFAULT_DIRECTORY_THRESHOLD = 2
ICON_DEFAULT_DIRECTORY_TYPE = 'Threshold'
ICON_THEME_SECTION = 'Icon Theme'
ICON_DEFAULT_CACHE_TIME = 5000
ICON_EXTENSIONS = ['png', 'svg', 'xpm']

# http://standards.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html#directory_layout
ICON_THEME_DIRS = {}
for xdgDataDir in XdgBasedir.dataDirs
	ICON_THEME_DIRS[Path.join(xdgDataDir, 'icons')] = 1
ICON_THEME_DIRS = Object.keys ICON_THEME_DIRS

ICON_DIRS = {}
ICON_DIRS[v] = 1 for v in ICON_THEME_DIRS
ICON_DIRS["#{process.env.HOME}/.icons"] = 1
ICON_DIRS["/usr/share/pixmaps"] = 1
ICON_DIRS = Object.keys ICON_DIRS

# http://standards.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html#ftn.idm140276330134880 
ICON_FALLBACK_THEME = 'hicolor'

module.exports = {
	ICON_THEME_SECTION
	ICON_DIRS
	ICON_THEME_DIRS
	ICON_FALLBACK_THEME
	ICON_DEFAULT_DIRECTORY_THRESHOLD
	ICON_DEFAULT_DIRECTORY_TYPE
	ICON_EXTENSIONS
	ICON_DEFAULT_CACHE_TIME
}

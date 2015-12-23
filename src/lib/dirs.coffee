XdgBasedir = require 'xdg-basedir'
Path = require 'path'

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
FALLBACK_ICON_THEME = 'hicolor'

module.exports = {
	ICON_DIRS
	ICON_THEME_DIRS
	FALLBACK_ICON_THEME
}

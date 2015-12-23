TV4 = require 'tv4'
JSON_SCHEMA = require '../src/lib/icon-theme-schema'
IconManager = require '../src/lib/icon-manager'

IconManager.on 'error', (err) ->
	console.log "ERROR", err
IconManager.on 'loaded', ->
	# console.log IconManager.listInstalledThemes()
	IconManager.findIcon 'ums', 96, 'Adwaita', (err, filename) =>
		console.log arguments
IconManager.init()

# parse = require '../src/lib/theme-parser'

# theme = new IconTheme('hicolor')
# console.log theme
# x = new IconDirectory({
#     id: 'hicolor'
#     name: 'Hicolor'
#     comment:
#         value: 'foo'
#     directories: [
#         foo: 'ba'
#     ]
# }).json
# console.log x


# file = '/usr/share/icons/hicolor/index.theme'
# parse file, (err, parsed) ->
#     parsed.id = 'hicolor'
#     console.log TV4.validateResult(parsed, JSON_SCHEMA)
#     # console.log parsed

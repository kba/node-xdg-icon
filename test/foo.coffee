TV4              = require 'tv4'
JSON_SCHEMA      = require '../src/lib/icon-theme-validator'
IconManagerClass = require '../src/lib/icon-manager'
Async            = require 'async'
log = require('../src/lib/log')(module)

IconManager = new IconManagerClass {
	extensions: ['png']
	cacheTime: 5000
}

IconManager.on 'error', (err) ->
	console.log "ERROR", err
IconManager.on 'loaded', ->
	# log.debug IconManager.listThemes (err, themes) ->
	Async.series {
		# 1: (cb) -> IconManager.findIcon 'battery_empty', 32, 'Faenza', (err, filename) =>
		#     console.log arguments
		#     cb()
		# 2: (cb) -> IconManager.findIcon 'ums', 57, 'Faenza', (err, filename) =>
		#     console.log arguments
		#     cb()
		# 3: (cb) -> IconManager.findIcon 'firefox', 57, 'Faenza', (err, filename) =>
		#     console.log arguments
		#     cb()
		# 4: (cb) -> IconManager.findBestIcon ['ums', 'battery_empty', 'firefox'], 57, 'Faenza', (err, filename) =>
		#     console.log arguments
		#     cb()
		5: (cb) -> IconManager.findBestIcon ['a', 'b', 'battery'], 57, 'Faenza', (err, filename) =>
			console.log arguments
			cb()
	}
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

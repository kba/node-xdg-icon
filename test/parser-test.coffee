
parse = require '../src/lib/theme-parser'
file = '/usr/share/icons/hicolor/index.theme'

parse file, (err, parsed) ->
	console.log err, parsed

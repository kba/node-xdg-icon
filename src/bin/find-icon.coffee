IconManager = require '../lib/icon-manager'
Path = require 'path'

usage = ->
	console.log "#{Path.basename process.argv[1]} <icon-name> [size] [theme]"
	process.exit 1

args = []
args.push v for v in process.argv.slice(2)
usage() unless args[0]
if args[1]
	args[1] = parseInt args[1]
else
	args[1] = 48

args.push (err, filename) ->
	console.log 'Not found' if err
	console.log filename

process.env.LOGLEVEL = 'error'

icon = new IconManager(
	cacheProfiling: false
)
icon.on 'loaded', ->
	icon.findIcon.apply(icon, args)
icon.init()


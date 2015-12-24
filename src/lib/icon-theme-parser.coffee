Readline = require('readline')
Fs       = require('fs')

log = require('./log')(module)
{
	ICON_THEME_SECTION
	ICON_DEFAULT_DIRECTORY_THRESHOLD
	ICON_DEFAULT_DIRECTORY_TYPE
} = require './icon-constants'


_ucfirst = (v) ->
	return v[0].toUpperCase() + v.substr(1)

_parseLocaleString = (key,value) ->
	openBracesPos =  key.indexOf('[')
	if openBracesPos == -1
		locale = null
		return [key, { value, locale }]
	locale = key.substring(openBracesPos+1, key.length-1)
	key = key.substring(0, openBracesPos)
	return [key, {locale, value}]

module.exports = (filename, parsed, cb) ->

	ctx = null
	parsed           or= {}
	parsed.Inherits  or= []
	parsed.Name      or= []
	parsed.Comment   or= []
	parsed._dirCache or= {}
	directories = {}

	lr = Readline.createInterface {
		input: Fs.createReadStream(filename)
	}

	lr.on 'error', (err) ->
		return cb "Problem parsing #{index_theme}: #{err}" if err
		cb err

	lr.on 'line', (line) ->
		line = line.trim()
		if line == '' or line[0] == '#'
			return
		if line[0] == '['
			ctx = line.substr(1, line.indexOf(']') - 1)
		else
			[k,v] = line.split '=', 2
			if ctx == ICON_THEME_SECTION
				if k is 'Hidden'
					parsed[k] = v == 'true'
				else if k is 'Directories'
					for dir in v.split(/\s*,\s*/)
						continue unless dir
						directories[dir] = {
							id: dir
							_cache: {}
							Threshold: ICON_DEFAULT_DIRECTORY_THRESHOLD
							Type: ICON_DEFAULT_DIRECTORY_TYPE
						}
				else if k is 'Inherits'
					parsed.Inherits.push parent for parent in v.split(/\s*,\s*/)
				else if k.match /^(Name|Comment)/
					[k,v] = _parseLocaleString(k,v)
					parsed[k].push = v
				else
					if ctx isnt ICON_THEME_SECTION
						log.debug "Unknown key '#{k}' in [#{ctx}] of '#{filename}'"
			else
				switch k
					when 'Size', 'MinSize', 'MaxSize'
						directories[ctx][k] = parseInt v
					else
						if k is 'Context' or k is 'Type'
							v = _ucfirst v
						directories[ctx][k] = v

	lr.on 'close', () ->
		parsed.Directories = (v for k,v of directories)
		cb null, parsed

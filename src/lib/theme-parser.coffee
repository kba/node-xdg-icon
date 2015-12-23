Readline = require('readline')
Fs = require('fs')

ICON_THEME_CTX = 'Icon Theme'

_lcfirst = (v) ->
	return v[0].toLowerCase() + v.substr(1)

_parseLocaleString = (k,v) ->
	openBracesPos =  k.indexOf('[')
	if openBracesPos == -1
		return { value: v }
	ret = {}
	ret.value = k.substr(0, openBracesPos - 1)
	ret.locale = k.substr(openBracesPos, k.indexOf(']') - 1)
	return ret

module.exports = (filename, parsed, cb) ->

	ctx = null
	parsed or= {}
	parsed.inherits or= []
	directories = {}

	lr = Readline.createInterface {
		input: Fs.createReadStream(filename)
	}

	lr.on 'error', (err) ->
		return cb "Problem parsing #{index_theme}: #{err}" if err
		cb err

	lr.on 'line', (line) ->
		line = line.trim()
		if line == ''
			return
		if line[0] == '['
			ctx = line.substr(1, line.indexOf(']') - 1)
		else
			[k,v] = line.split '=', 2
			if ctx == ICON_THEME_CTX
				if k is 'Hidden'
					parsed.hidden = v == 'true'
				else if k is 'Directories'
					for dir in v.split(/\s*,\s*/)
						directories[dir] = {
							id: dir
							threshold: 2
							type: 'Threshold'
							files: {}
						}
				else if k is 'Inherits'
					parsed.inherits or= []
					parsed.inherits.push parent for parent in v.split(/\s*,\s*/)
				else if k.match /^Name/
					parsed.name or= []
					parsed.name.push _parseLocaleString(k,v)
				else if k.match /^Comment/
					parsed.comment or= []
					parsed.comment.push _parseLocaleString(k,v)
				# else
				#     console.log "Unknown key #{k} in [#{ctx}]"
			else
				switch k
					when 'Size', 'MinSize', 'MaxSize'
						directories[ctx].size = parseInt v
					else
						directories[ctx][_lcfirst k] = v

	lr.on 'close', () ->
		parsed.directories = (v for k,v of directories)
		cb null, parsed


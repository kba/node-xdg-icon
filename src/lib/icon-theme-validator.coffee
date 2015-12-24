TV4          = require 'tv4'
JsonPointer  = require 'jsonpointer'

log = require('./log')(module)

schema =
	title: 'XDG Icon Theme'
	$schema: "http://json-schema.org/draft-04/schema#",
	# http://standards.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html#idm140276333767712
	required: ['id', 'Name', 'Comment', 'Directories']
	properties:
		id:
			type: 'string'
		Name:
			type: 'array'
			items:
				$ref: '#/definitions/LocaleString'
		Comment:
			type: 'array'
			items:
				$ref: '#/definitions/LocaleString'
		Inherits:
			type: 'array'
			items: 
				type: 'string'
		Directories: 
			type: 'array'
			items:
				$ref: '#/definitions/IconDirectory'
		Hidden:
			type: 'boolean'
		Example:
			type: 'string'
	definitions:
		LocaleString:
			title: 'Localized string'
			type: 'object'
			properties:
				value:
					type: 'string'
				locale:
					type: 'string'
			require: ['value']
		# http://standards.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html#idm140276333799280
		IconDirectory:
			title: 'Icon Directory'
			type: 'object'
			required: ['Size', '_cache']
			properties:
				_cache:
					type: "object"
				Size:
					type: "integer"
				Context:
					enum: [ 'Actions', 'Animations', 'Applications', 'Apps',
							'Categories', 'Devices', 'Emblems', 'Emotes',
							'International', 'FileSystems', 'MimeTypes', 'Mimetypes',
							'Places', 'Status', 'Stock' ]
				Type:
					enum: ['Fixed', 'Scalable', 'Threshold']
				MaxSize:
					type: "integer"
				MinSize:
					type: "integer"
				Threshold:
					type: "integer"

module.exports = 
	schema: schema
	validate : (theme) ->
		result = TV4.validateResult theme, schema
		if not result.valid
			log.debug "Validation error", result.error
			if result.error.dataPath
				log.debug "Error Location", JsonPointer.get(theme, result.error.dataPath)
		return result

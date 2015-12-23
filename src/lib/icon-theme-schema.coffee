module.exports = {
	title: 'XDG Icon Theme'
	$schema: "http://json-schema.org/draft-04/schema#",
	# http://standards.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html#idm140276333767712
	required: ['id', 'name', 'comment', 'directories']
	properties:
		id:
			type: 'string'
		name:
			type: 'string'
		comment:
			type: 'array'
			items:
				$ref: '#/definitions/LocaleString'
		inherits:
			type: 'array'
			items: 
				type: 'string'
		directories: 
			type: 'array'
			items:
				$ref: '#/definitions/IconDirectory'
		hidden:
			type: 'boolean'
		example:
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
			properties:
				size:
					type: "integer"
				context:
					enum: [ 'Actions', 'Animations', 'Applications', 'Apps',
							'Categories', 'Devices', 'Emblems', 'Emotes',
							'International', 'FileSystems', 'MimeTypes', 'Places',
							'Status', 'Stock' ]
				type:
					enum: ['Fixed', 'Scalable', 'Threshold']
				maxSize:
					type: "integer"
				minSize:
					type: "integer"
				threshold:
					type: "integer"
				files:
					type: "array"
			required: ['size']
}

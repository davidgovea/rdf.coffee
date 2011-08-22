
# src/converter.coffee
((api) ->
	class api.Converter
		constructor: ->
		c: null
		_string: (s, a) ->
			unless Boolean(a).valueOf() or a.indexOf(":") < 0 then return api.createLiteral s, a
			return api.createLiteral s, api.ref a 
		_boolean: (b) -> return api.createLiteral (if b then "true" else "false"), api.ref 'xsd:boolean'
		_date: (d, ms) ->
			pad = (n) -> return if n < 10 then '0' + n else n
			s = d.getUTCFullYear() + "-" + pad(d.getUTCMonth() + 1) + '-' + pad(d.getUTCDate()) + 'T'
			s += pad(d.getUTCHours()) + ":" + pad(d.getUTCMinutes()) + ":" + pad(d.getUTCSeconds())
			if ms then s = (if d.getUTCMilliseconds() >0 then s + '.' + d.getUTCMilliseconds() else s)
			return api.createLiteral s += 'Z', api.ref 'xsd:dateTime'
		_number: (n) ->
			if n is Number.POSITIVE_INFINITY then return api.createLiteral 'INF', api.ref 'xsd:double'
			if n is Number.NEGATIVE_INFINITY then return api.createLiteral '-INF', api.ref 'xsd:double'
			if n is Number.NaN then return api.createLiteral 'NaN', api.ref 'xsd:double'
			n = n.toString()
			if api.Converter.INTEGER.test n then return api.createLiteral n, api.ref 'xsd:integer'
			if api.Converter.DECIMAL.test n then return api.createLiteral n, api.ref 'xsd:decimal'
			if api.Converter.DOUBLE.test n then return api.createLiteral n, api.ref 'xsd:double'
			throw new TypeError "Can't convert weird number: " + n
		convert: (l, r) ->
			switch typeof l
				when 'string' then return @_string l, r
				when 'boolean' then return @_boolean l
				when 'number' then return @_number l
				when 'object'
					switch l.constructor.name
						when 'Boolean' then return @_boolean l.valueOf()
						when 'Date' then return @_date l, r
						when 'Number' then return @_number l
			throw new TypeError "Cannot convert type: "+ l.constructor.name
	api.Converter.INTEGER = new RegExp("^(-|\\+)?[0-9]+$", "")
	api.Converter.DOUBLE = new RegExp("^(-|\\+)?(([0-9]+\\.[0-9]*[eE]{1}(-|\\+)?[0-9]+)|(\\.[0-9]+[eE]{1}(-|\\+)?[0-9]+)|([0-9]+[eE]{1}(-|\\+)?[0-9]+))$", "")
	api.Converter.DECIMAL = new RegExp("^(-|\\+)?[0-9]*\\.[0-9]+?$", "")

	api.converter = new api.Converter
	api.literal = (o,t) ->
		return api.converter.convert o, t		
)(rdf)


# src/interfaces.coffee
global = exports ? this
global.rdf = (->
	rdf = {}
	rdf.encodeString = (s) ->
		out		= ""
		skip	= false
		_g1		= 0
		_g		= s.length
		while _g1 < _g
			i	= _g1++
			if !skip
				code	= s.charCodeAt(i)
				if 55296 <= code and code <= 56319
					low		= s.charCodeAt( i + 1 )
					chr	= (code - 55296) * 1024 + (low - 56320) + 65536
					skip	= true
				if code > 1114111
					throw new Error("Char out of range")
				hex		= "00000000".concat((new Number(code)).toString(16).toUpperCase())
				if code	>= 65536
					out += "\\U" + hex.slice(-8)
				else
					if code >= 127 or code <= 31
						switch code
							when 9 then		out += "\\t"
							when 10 then	out += "\\n"
							when 13 then	out += "\\r"
							else 			out += "\\u" + hex.slice(-4)
					else
						switch code
							when 34	then	out += '\\"'
							when 92 then	out += "\\\\"
							else			out += s.charAt(i)
			else
				skip = !skip
		return out
	
	class rdf.BlankNode 
		constructor: ->
			@nominalValue = 'b'.concat(++rdf.BlankNode.NEXTID)
			@interfaceName = 'BlankNode'
		valueOf: ->
			@nominalValue
		equals: (o) ->
			if o?
				if not o.hasOwnProperty('interfaceName') then return @nominalValue is o
				if o.interfaceName is @interfaceName then return @nominalValue is o.nominalValue
			else return false
		toString: ->
			'_:'.concat(@nominalValue)
		toNT: ->
			rdf.encodeString(@toString())
		h: ->
			@nominalValue
	
	rdf.BlankNode.NEXTID = 0

	class rdf.NamedNode 
		constructor: (iri) ->
			@nominalValue = iri
			@interfaceName = 'NamedNode'
		valueOf: ->
			@nominalValue
		equals: (o) ->
			if o?
				if not o.hasOwnProperty('interfaceName') then return @nominalValue is o
				if o.interfaceName is @interfaceName then return @nominalValue is o.nominalValue
			else return false
		toString: ->
			@nominalValue.toString()
		toNT: ->
			'<' + rdf.encodeString(@toString()) + '>'
		h: ->
			@nominalValue

	class rdf.Literal
		constructor: (value, language, datatype, nativ) ->
			if typeof language is 'string' and language[0] is '@'
				language = language.slice 1
			@nominalValue = value
			@language = language
			@datatype = datatype
			@h = ->
				language + '|' + (if datatype then datatype.toString() else '') + '|' + value.toString()
			@valueOf = -> 
				if nativ is null then @nominalValue else nativ
			@interfaceName = 'Literal'
		equals: (o) ->
			if o?
				if not o.hasOwnProperty('interfaceName') then return @valueOf() is o
				if o.interfaceName isnt @interfaceName then return false
			@h() is o.h()
		toString: ->
			@nominalValue.toString()
		toNT: ->
			s = '"' + rdf.encodeString(@nominalValue) + '"'
			if @language then return s.concat('@' + @language)
			if @datatype then return s.concat('^^' + @datatype.toNT())
			return s
		
	class rdf.Triple
		constructor: (s, p, o) ->
			# console.log s.h()
			# console.log p
			# console.log o
			@subject = @s =s
			@property = @p = p
			@object = @o = o
		equals: (t) ->
			@s.equals(t.s) and @p.equals(t.p) and @o.equals(t.o)
		toString: ->
			@s.toNT() + " " + @p.toNT() + " " +@o.toNT() + " ."
		# getS: ->
		# 	@subject
		# getP: ->
		# 	@property
		# getO: ->
		# 	@object
	
	class rdf.Graph
		constructor: (a) ->
			@_graph	= []
			@_spo	= {}
			if a? then @addArray a
		length: ->
			@_graph.length
		add: (t) ->
			# console.log t.s
			@_spo[t.s.h()] or (@_spo[t.s.h()] = {})
			@_spo[t.s.h()][t.p.h()] or (@_spo[t.s.h()][t.p.h()] = {})
			if not @_spo[t.s.h()][t.p.h()][t.o.h()]
				@_spo[t.s.h()][t.p.h()][t.o.h()] = t
				@_graph.push(t)
				_.forEach(@actions, (a)->
					a.run(t)
				)
			return this
		addArray: (a) ->
			if _.isArray(a)
				g = this
				b = _.forEach(a, (t)->
					g.add(t)
				)
			return this
		remove: (t) ->
			@_spo[t.s.h()] and @_spo[t.s.h()][t.p.h()] and @_spo[t.s.h()][t.p.h()][t.o.h()] and (
				delete @_spo[t.s.h()][t.p.h()][t.o.h()] and
				@_graph.splice(_.indexOf(@_graph, t), 1)
			)
			return this
		removeMatches: (s,p,o) ->
			s = if arguments[0] is undefined then null else s
			p = if arguments[1] is undefined then null else p
			o = if arguments[2] is undefined then null else o
			r = []
			_.forEach(this, (t, g)->
				(s is null or t.s.equals(s)) and (p is null or t.p.equals(p)) and (o is null or t.o.equals(o)) and r.push(t)
			)
			for i in r
				@remove i
			return this
		toArray: ->
			@_graph.slice(0)
		some: (cb) ->
			_.some(@_graph, cb)
		every: (cb) ->
			_.every(@_graph, cb)
		filter: (cb) ->
			new rdf.Graph(_.filter(@_graph, cb))
		forEach: (cb) ->
			g = this
			_.forEach(@_graph, (t)->cb(t,g))
		match: (s,p,o,l) ->
			s = if arguments[0] is undefined then null else s
			p = if arguments[1] is undefined then null else p
			o = if arguments[2] is undefined then null else o
			l = if arguments[3] is undefined then null else l
			c = 0
			if l < 1 then l=-1
			return new rdf.Graph(_.filter(@_graph, (t)->
				if c is l then return false
				return (s is null or t.s.equals(s)) and (p is null or t.p.equals(p)) and (o is null or t.o.equals(o)) and ++c
			))
		merge: (g) ->
			return new rdf.Graph().addAll(this).addAll(g)
		addAll: (g) ->
			return @addArray(g.toArray())
		actions: []
		addActions: (a,r) ->
			if r then _.forEach(this, (t,g)->a.run(t,g))
			@actions.push(a)
			return this

	class rdf.TripleAction
		constructor: (test, action) ->
			@test = test
			@action = action
		run: (t,g) ->
				if @test t then @action t, g

	class rdf.PrefixMap
		constructor: (i) ->
			if i? then @addAll i
		resolve: (curie) ->
			index = curie.indexOf(":")
			if index < 0 or curie.indexOf("//") >= 0 then return null
			prefix = curie.slice(0, index).toLowerCase()
			if not this[prefix] then return null
			return this[prefix].concat( curie.slice(++index) )
		shrink: (iri) ->
			#console.log this.rdf
			for pref, pval of this
				if iri.substr(0, pval.length) is pval
					return pref + ':' + iri.slice(pval.length)
			return iri
		setDefault: (iri) ->
			this[''] = iri
		addAll: (prefixes, override) ->
			for p of prefixes
				if not this[p] or override
					this[p] = prefixes[p]
			return this

	class rdf.TermMap
		constructor: (i) ->
			if i? then @addAll i
		resolve: (term) ->
			if this[term] then return this[term]
			if this[""] then return this[""].concat(term)
			return null
		shrink: (iri) ->
			for t of this
				if this[t] is iri then return t
			return iri
		setDefault: (iri) ->
			this[''] = iri
		addAll: (terms, override) ->
			for t of terms
				if not this[t] or override
					this[t] = terms[t]
			return this

	class rdf.Profile
		constructor: (i) ->
			if i? then @importProfile i
		prefixes: new rdf.PrefixMap
		terms: new rdf.TermMap
		resolve: (tp) ->
			return if tp.indexOf(":") >= 0 then @prefixes.resolve(tp) else @terms.resolve(tp)
		setDefaultVocabulary: (iri) ->
			@terms.setDefault(iri)
		setDefaultPrefix: (iri) ->
			@prefixes.setDefault(iri)
		setTerm: (term, iri) ->
			@terms[term] = iri
		setPrefix: (prefix, iri) ->
			@prefixes[prefix] = iri
		importProfile: (profile, override) ->
			if not profile then return this
			@prefixes.addAll(profile.prefixes, override)
			@terms.addAll(profile.terms, override)
			return this

	rp = 
		terms: {}
		prefixes:
			owl: "http://www.w3.org/2002/07/owl#"
			rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
			rdfs: "http://www.w3.org/2000/01/rdf-schema#"
			rdfa: "http://www.w3.org/ns/rdfa#"
			xhv: "http://www.w3.org/1999/xhtml/vocab#"
			xml: "http://www.w3.org/XML/1998/namespace"
			xsd: "http://www.w3.org/2001/XMLSchema#"
	xsd = {}
	for itemtype in x=[
		'string','boolean','dateTime','date','time','int','double','float','decimal','integer',
		'nonPositiveInteger','negativeInteger','long','int','short','byte','nonNegativeInteger',
		'unsignedLong','unsignedInt','unsignedShort','unsignedByte','positiveInteger'
	]
		xsd[itemtype] = rp.prefixes.xsd.concat(itemtype)

	class rdf.RDFEnvironment 
		constructor: ->
			_.extend this, new rdf.Profile(rp)
		createBlankNode: ->
			new rdf.BlankNode
		createNamedNode: (iri) ->
			new rdf.NamedNode(iri)
		createLiteral: (value) ->
			l = null
			dt = arguments[2]
			v = value
			if arguments[1]
				if arguments[1].hasOwnProperty('interfaceName') then dt = arguments[1]
				else l = arguments[1]
			if dt
				switch dt.valueOf()
					when xsd.string then v = new String(v)
					when xsd['boolean'] then v = (new Boolean(if v is false then false else v)).valueOf()
					when xsd['float'], xsd.integer, xsd['long'], xsd['double'], xsd.decimal, \
					xsd.nonPositiveInteger, xsd.nonNegativeInteger, xsd.negativeInteger, \
					xsd['int'], xsd.unsignedLong, xsd.positiveInteger, xsd['short'], \
					xsd.unsignedInt, xsd['byte'], xsd.unsignedShort, xsd.unsignedByte then v = (new Number(v)).valueOf()
					when xsd['date'], xsd.time, xsd.dateTime then v = new Date(v)
			new rdf.Literal(value, l, dt, v)
		createTriple: (s,p,o) ->
			new rdf.Triple(s,p,o)
		createGraph: (a) ->
			new rdf.Graph(a)
		createAction: (t,a) ->
			new rdf.TripleAction(t,a)
		createProfile: (empty) ->
			new rdf.Profile(if not empty then this else null)
		createTermMap: (empty) ->
			new rdf.TermMap(if not empty then @terms else null)
		createPrefixMap: (empty) ->
			new rdf.PrefixMap(if not empty then @prefixes else null)
	
	env = new rdf.RDFEnvironment

	for own key of rdf
		env[key] = rdf[key]
	
	return rdf = env

)()

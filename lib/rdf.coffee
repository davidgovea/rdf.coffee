
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
			#if not o.hasOwnProperty('interfaceName') then 
			return @nominalValue is o
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
			if not o.hasOwnProperty('interfaceName') then return @valueOf() is o
			if o.interfaceName isnt @interfaceName then return false
			@h is o.h()
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

# src/hash.coffee
((api) ->
	class api.Hash
		constructor: (p) ->
			@empty()
		h: null
		get: (k) -> return @h[k]
		set: (k, v) -> @h[k] = v
		empty: -> @h = {}
		exists: (k) -> return @h.hasOwnProperty k
		keys: (proto) ->
			keys = []
			proto = not proto
			for i of @h
				if proto and Object.prototype[i] then continue
				keys.push i
			return keys
		remove: (k) ->
			r = @get k
			delete @h[k]
			return r
		toArray: ->
			a = new Array
			_.forEach(@keys(), (k) ->
				a.push @get k
			, this)
			return a
		toString: -> return JSON.stringify @h
)(rdf)

# src/iri.coffee
((api) ->
	SCHEME_MATCH = new RegExp("^[a-z0-9-.+]+:", "i")

	class api.IRI
		constructor: (iri) ->
			@value = iri
		toString: -> return @value
		defrag: ->
			i = @value.indexOf "#"
			return if i< 0 then this else new api.IRI(@value.slice 0, i)
		isAbsolute: -> return @scheme() isnt null and @heirpart() isnt null and @fragment() is null
		toAbsolute: -> 
			if @scheme() is null and @heirpart() is null then throw new Error "IRI must have a scheme and a heirpart!"
			return @resolveReference(@value).defrag()
		authority: ->
			heirpart = @heirpart()
			if heirpart.substring(0, 2) isnt "//" then return null
			authority = heirpart.slice 2
			q = authority.indexOf "/"
			return if q >= 0 then authority.substring(0, q) else authority
		fragment: ->
			i = @value.indexOf "#"
			return if i < 0 then null else @value.slice i
		heirpart: ->
			heirpart = @value
			q = heirpart.indexOf "?"
			if q >= 0 then heirpart = heirpart.substring 0, q
			else 
				q = heirpart.indexOf "#"
				if q >=0 then heirpart = heirpart.substring 0, q
			q2 = @scheme()
			if q2 isnt null then heirpart = heirpart.slice 1 + q2.length
			return heirpart
		host: ->
			host = @authority()
			q = host.indexOf "@"
			if q >= 0 then host = host.slice ++q
			if host.indexOf("[") is 0
				q = host.indexOf "]"
				if q > 0 then return host.substring 0, q
			q = host.lastIndexOf ":"
			return if q >=0 then host.substring(0, q) else host
		path: ->
			q = @authority()
			if q is null then return @heirpart()
			return @heirpart().slice q.length + 2
		port: ->
			host = @authority()
			q = host.indexOf "@"
			if q >= 0 then host = host.slice ++q
			if host.indexOf("[") is 0
				q = host.indexOf "]"
				if q > 0 then return host.substring 0, q
			q = host.lastIndexOf ":"
			if q < 0 then return null
			host = host.slice ++q
			return if host.length is 0 then null else host
		query: ->
			q = @value.indexOf "?"
			if q < 0 then return null
			f = @value.indexOf "#"
			if f < 0 then return @value.slice q
			return @value.substring q, f
		removeDotSegments: (input) ->
			output = ""
			q = 0
			while input.length > 0
				if input.substr(0, 3) is "../" or input.substr(0, 2) is "./"
					input = input.slice input.indexOf "/"
				else
					if input is "/."
						input = "/"
					else
						if input.substr(0, 3) is "/./"
							input = input.slice 2
						else
							if input.substr(0, 4) is "/../" or input is "/.."
								input = if input is "/.." then "/" else input.slice 3
								q = output.lastIndexOf "/"
								output = if q >= 0 then output.substring 0, q else ""
							else
								if input.substr(0, 2) is ".." or input.substr(0, 1) is "."
									input = input.slice input.indexOf "."
									q = input.indexOf "."
									if q >= 0 then input = input.slice(q)
								else
									if input.substr(0, 1) is "/"
										output += "/"
										input = input.slice 1
									q = input.indexOf "/"
									if q < 0
										output += input
										input = ""
									else
										output += input.substring 0, q
										input = input.slice q
			return output
		resolveReference: (ref) ->
			reference = new api.IRI ref.toString()
			T =
				scheme: ""
				authority: ""
				path: ""
				query: ""
				fragment: ""
			q = ""
			if reference.scheme() isnt null
				T.scheme = reference.scheme()
				q = reference.authority()
				T.authority += if q isnt null then "//" + q else ""
				T.path = @removeDotSegments reference.path()
				q = reference.query()
				T.query += if q isnt null then q else ""
			else
				q = reference.authority()
				if q isnt null
					T.authority = "//" + q
					T.path = @removeDotSegments reference.path()
					q = reference.query()
					T.query +=if q isnt null then q else ""
				else
					q = reference.path()
					if q is "" or q is null
						T.path = @path()
						q = reference.query()
						if q isnt null
							T.query += q
						else
							q = @query()
							T.query += if q isnt null then q else ""
					else
						if q.substring(0, 1) is "/"
							T.path = @removeDotSegments q
						else
							if @path() isnt null
								q2 = @path().lastIndexOf "/"
								if q2 >= 0
									T.path = @path().substring 0, ++q2
								T.path += reference.path()
							else
								T.path = "/" + q
							T.path = @removeDotSegments(T.path)
						q = reference.query()
						T.query += if q isnt null then q else ""
					q = @authority()
					T.authority = if q isnt null then "//" + q else ""
				T.scheme = @scheme()
			q = reference.fragment()
			T.fragment = if q isnt null then q else ""
			return new api.IRI T.scheme + ":" + T.authority + T.path + T.query + T.fragment
		scheme: ->
			scheme = @value.match SCHEME_MATCH
			return if scheme is null then null else scheme.shift().slice 0, -1
		userInfo: ->
			authority = @authority()
			q = authority.indexOf "@"
			return if q < 0 then null else authority.substring 0, q
	
	api.createIRI = (i) ->
		return new api.IRI i
)(rdf)

# src/parsers.coffee
((api) ->
	if not api.parsers then api.parsers = {}
	api.parsers.u8 = new RegExp("\\\\U([A-F0-9]{8})", "g")
	api.parsers.u4 = new RegExp("\\\\u([A-F0-9]{4})", "g")
	api.parsers.hexToChar = (hex) ->
		result = ""
		n = parseInt(hex, 16)
		if n <= 65535
			result += String.fromCharCode(n)
		else if n <= 1114111 
			n -= 65536
			result += String.fromCharCode(55296 + (n >> 10), 56320 + (n & 1023))
		else throw new Error("code point isn't known: " + n)
		return result
	api.parsers.decodeString = (str) ->
		str = str.replace(api.parsers.u8, (matchstr, parens) -> return api.parsers.hexToChar(parens))
		str = str.replace(api.parsers.u4, (matchstr, parens) -> return api.parsers.hexToChar(parens))
		str = str.replace(new RegExp("\\\\t", "g"), "\t")
		str = str.replace(new RegExp("\\\\n", "g"), "\n")
		str = str.replace(new RegExp("\\\\r", "g"), "\r")
		str = str.replace(new RegExp('\\\\"', "g"), '"')
		str = str.replace(new RegExp("\\\\\\\\", "g"), "\\")
		return str
	
	class api.parsers.NTriples
		constructor: (context) ->
			@context = context
			@bnHash = new api.Hash
		context: null
		quick: null
		bnHash: null
		graph: null
		filter: null
		processor: null
		base: null
		parse: (toparse, cb, base, filter, graph) ->
			@graph = graph ? @context.createGraph()
			@filter = filter
			@quick = false
			@base = base
			@internalParse(toparse)
			cb?(@graph)
			return true
		process: (toparse, processor, base, filter) ->
			@processor = processor
			@filter = filter
			@quick = true
			@base = base
			return @internalParse(toparse)
		getBlankNode: (id) ->
			if @bnHash.exists(id) then return @bhHash.get(id)
			bn = @context.createBlankNode()
			@bnHash.set(id, bn)
			return bn
		internalParse: (toparse) ->
			data = new String toparse
			lines = data.split api.parsers.NTriples.eolMatcher
			_.forEach(lines, (a, b, c) ->
				@readLine a, b, c
			, this)
		negotiateLiteral: (plain) ->
			if plain.slice(-1) is '"' then return @context.createLiteral(api.parsers.decodeString(plain.slice(1, -1)))
			lang = plain.match(api.parsers.NTriples.trailingLanguage)
			if lang isnt null then return @context.createLiteral(api.parsers.decodeString(plain.slice(1, -1 - lang.shift().length)), lang.pop())
			parts = plain.match(api.parsers.NTriples.typedLiteralMatcher)
			return @context.createLiteral(api.parsers.decodeString(parts[1]), api.createNamedNode(parts.pop()))
		readLine: (line, index, array) ->
			if api.parsers.NTriples.isComment.test(line) or api.parsers.NTriples.isEmptyLine.test(line) then return
			line = line.replace(api.parsers.NTriples.initialWhitespace, "").replace(api.parsers.NTriples.trailingWhitespace, "")
			spo = line.split(api.parsers.NTriples.whitespace, 2)
			spo.push(line.replace(api.parsers.NTriples.objectMatcher, "$3"))
			if spo[0].charAt(0) is "<"
				s = @context.createNamedNode(api.parsers.decodeString(spo[0].slice(1, -1)))
			else
				s = @getBlankNode(spo[0].slice(2))
			spo.shift()
			p = @context.createNamedNode(spo.shift().slice(1, -1))
			switch spo[0].charAt(0)
				when "<" then 	o = @context.createNamedNode(api.parsers.decodeString(spo[0].slice(1, -1)))
				when "_" then 	o = @getBlankNode(spo[0].slice(2))
				else 			o = @negotiateLiteral(spo[0])
			triple = @context.createTriple(s, p, o)
			$use = true
			if @filter? then $use = @filter(triple, null, null)
			if not $use then return
			if @quick then @processor(triple) else @graph.add(triple)

	api.parsers.NTriples.isComment = new RegExp("^[ \t]*#", "")
	api.parsers.NTriples.isEmptyLine = new RegExp("^[ \t]*$", "")
	api.parsers.NTriples.initialWhitespace = new RegExp("^[ \t]+", "")
	api.parsers.NTriples.trailingWhitespace = new RegExp("[. \t]+$", "")
	api.parsers.NTriples.whitespace = new RegExp("[ \t]+", "")
	api.parsers.NTriples.objectMatcher = new RegExp("^([^ \t]+)[ \t]+([^ \t]+)[ \t]+(.*)$", "")
	api.parsers.NTriples.trailingLanguage = new RegExp("@([a-z]+[-a-z0-9]+)$", "")
	api.parsers.NTriples.typedLiteralMatcher = new RegExp('^"(.*)"(.{2})<([^>]+)>$', "")
	api.parsers.NTriples.eolMatcher = new RegExp("\r\n|\n|\r", "g")
	

	class api.parsers.Turtle 
		constructor: (context) ->
			@context = context
			@bnHash = new api.Hash
		bnHash: null
		context: null
		filter: null
		processor: null
		quick: null
		graph: null
		base: null
		parse: (doc, cb, base, filter, graph) ->
			@graph = graph ? this.context.createGraph()
			@filter = filter
			@quick = false
			@base = base
			@parseStatements new String doc
			cb? @graph
			return true
		process: (doc, processor, base, filter) ->
			@processor = processor
			@filter = filter
			@quick = true
			@base = base
			return @parseStatements new String doc
		t: ->
			return o: null
		parseStatements: (s) ->
			s = s.toString()
			while s.length > 0
				s = @skipWS s
				if s.length is 0 then return true
				s = if s.charAt(0) is "@" then @consumeDirective(s) else @consumeStatement(s)
				@expect s, "."
				s = @skipWS s.slice 1
			return true
		add: (t) ->
			$use = true
			if @filter? and not @filter t then return
			if @quick then @processor t else @graph.add t
		consumeBlankNode: (s, t) ->
			t.o = @context.createBlankNode()
			s = @skipWS s.slice 1
			if s.charAt(0) is "]" then return s.slice 1
			s = @skipWS @consumePredicateObjectList s, t
			@expect s, "]"
			return @skipWS s.slice 1
		consumeCollection: (s, subject) ->
			subject.o = @context.createBlankNode()
			listject = @t()
			listject.o = subject.o
			s = @skipWS s.slice 1
			cont = s.charAt(0) isnt ")"
			if not cont then subject.o = @context.createNamedNode @context.resolve "rdf:nil"
			while cont
				o = @t()
				switch s.charAt 0
					when "[" then s = @consumeBlankNode s, o
					when "_" then s = @consumeKnownBlankNode s, o
					when "(" then s = @consumeCollection s, o
					when "<" then s = @consumeURI s, o
					when '"' then s = @consumeLiteral s, o
					else
						token = s.match(api.parsers.Turtle.simpleObjectToken).shift()
						if token.charAt(token.length-1) is ")" then token = token.substring 0, token.length-1
						if token is "false" or token is "true"
							o.o = @context.createLiteral token, @context.createNamedNode @context.resolve "xsd:boolean"
						else if token.indexOf(":") > -1
							o.o = @context.resolve token
						else if api.parsers.Turtle.tokenInteger.test token
							o.o = @context.createLiteral token, @context.createNamedNode @context.resolve "xsd:integer"
						else if api.parsers.Turtle.tokenDouble.test token
							o.o = @context.createLiteral token, @context.createNamedNode @context.resolve "xsd:double"
						else if api.parsers.Turtle.tokenDecimal.test token
							o.o = @context.createLiteral token, @context.createNamedNode @context.resolve "xsd:decimal"
						else
							throw new Error "unrecognized token: "+token
						s = s.slice token.length
				@add @context.createTriple listject.o, @context.createNamedNode(@context.resolve("rdf:first")), o.o
				s = @skipWS s
				cont = s.charAt(0) isnt ")"
				if cont
					@add @context.createTriple listject.o, @context.createNamedNode(@context.resolve("rdf:rest")), listject.o = @context.createBlankNode()
				else
					@add @context.createTriple listject.o, @context.createNamedNode(@context.resolve("rdf:rest")), @context.createNamedNode(@context.resolve("rdf.nil"))
			
			return @skipWS s.slice 1
		consumeDirective: (s) ->
			p = 0
			if s.substring(1, 7) is "prefix"
				s = @skipWS s.slice 7
				p = s.indexOf ":"
				prefix = s.substring 0, p
				s = @skipWS s.slice ++p
				@expect s, "<"
				prefixUri = api.parsers.decodeString s.substring 1, p = s.indexOf ">"
				if prefixUri isnt "" then @context.setPrefix(prefix, prefixUri)
				s = @skipWS s.slice ++p
			else if s.substring(1, 5) is "base"
				s = @skipWS s.slice 5
				@expect s, "<"
				@base = @context.createIRI api.parsers.decodeString s.substring 1, p = s.indexOf ">"
				s = @skipWS s.slice ++ p
			else throw new Error "Unknown directive: " + s.substring 0, 50
			return s
		consumeKnownBlankNode: (s, t) ->
			@expect s "_:"
			bname = s.slice(2).match(api.parsers.Turtle.simpleToken).shift()
			t.o = @getBlankNode(bname)
			return s.slice bname.length + 2
		consumeLiteral: (s,o) ->
			value = ""
			hunt = true
			end = 0
			if s.substring(0, 3) is '"""'
				end = 3
				while hunt
					end = s.indexOf '"""', end
					if hunt = s.charAt(end - 1) is "\\" then end++
				value = s.substring 3, end
				s = s.slice value.length + 6
			else
				while hunt
					end = s.indexOf '"', end + 1
					hunt = s.charAt(end - 1) is "\\"
				value = s.substring 1, end
				s = s.slice value.length + 2
			value = api.parsers.decodeString value
			switch s.charAt 0
				when "@"
					token = s.match(api.parsers.Turtle.simpleObjectToken).shift()
					o.o = @context.createLiteral value, token.slice 1
					s = s.slice token.length
				when "^"
					token = s.match(api.parsers.Turtle.simpleObjectToken).shift().slice 2
					if token.charAt(0) is "<"
						o.o = @context.createLiteral value, @context.createNamedNode token.substring(1, token.length - 1)
					else
						o.o = @context.createLiteral value, @context.createNamedNode @context.resolve token
					s = s.slice token.length + 2
				else
					o.o = @context.createLiteral value
			return s
		consumeObjectList: (s, subject, property) ->
			cont = true
			while cont
				o = @t()
				switch s.charAt 0
					when "[" then s = @consumeBlankNode 		s, o
					when "_" then s = @consumeKnownBlankNode 	s, o
					when "(" then s = @consumeCollection 		s, o
					when "<" then s = @consumeURI 				s, o
					when '"' then s = @consumeLiteral 			s, o
					else
						token = s.match(api.parsers.Turtle.simpleObjectToken).shift()
						if token.charAt(token.length - 1) is "."
							token = token.substring 0, token.length - 1
						if token is "false" or token is "true"
							o.o = @context.createLiteral token, @context.createNamedNode @context.resolve "xsd:boolean"
						else if token.indexOf(":") > -1
							o.o = @context.createNamedNode @context.resolve token
						else if api.parsers.Turtle.tokenInteger.test token
							o.o = @context.createLiteral token, @context.createNamedNode @context.resolve "xsd:integer"
						else if api.parsers.Turtle.tokenDouble.test token
							o.o = @context.createLiteral token, @context.createNamedNode @context.resolve "xsd:double"
						else if api.parsers.Turtle.tokenDecimal.test token
							o.o = @context.createLiteral token, @context.createNamedNode @context.resolve "xsd:decimal"
						else
							throw new Error "unrecognized token: "+token
						s = s.slice token.length
				@add @context.createTriple subject.o, property, o.o
				s = @skipWS s
				cont = s.charAt(0) is ","
				if cont then s = @skipWS s.slice 1
			return s
		consumePredicateObjectList: (s, subject) ->
			cont = true
			while cont
				predicate = s.match(api.parsers.Turtle.simpleToken).shift()
				property = null
				if predicate is "a"
					property = @context.createNamedNode @context.resolve "rdf:type"
				else
					switch predicate.charAt 0
						when "<" then	property = @context.createNamedNode api.parsers.decodeString predicate.substring(1, predicate.indexOf(">"))
						else 			property = @context.createNamedNode @context.resolve predicate
				s = @skipWS s.slice predicate.length
				s = @consumeObjectList s, subject, property
				cont = s.charAt(0) is ";"
				if cont
					s = @skipWS s.slice 1
					next = s.charAt 0
					if next is "." or next is "]" then cont = false
			return s
		consumeQName: (s, t) ->
			qname = s.match(api.parsers.Turtle.simpleToken).shift()
			t.o = @context.createNamedNode @context.resolve qname
			return s.slice qname.length
		consumeStatement: (s) ->
			t = @t()
			switch s.charAt 0
				when "["
					s = @consumeBlankNode s, t
					if s.charAt(0) is "." then return s
				when "_" then	s = @consumeKnownBlankNode	s, t
				when "(" then	s = @consumeCollection		s, t
				when "<" then	s = @consumeURI				s, t
				else 			s = @consumeQName			s, t
			s = @consumePredicateObjectList @skipWS(s), t
			return s
		consumeURI: (s, t) ->
			@expect s, "<"
			p = 0
			t.o = api.parsers.decodeString s.substring(1, p = s.indexOf ">")
			if @base then t.o = @base.resolveReference t.o
			t.o = @context.createNamedNode t.o
			return s.slice ++p
		expect: (s, t) ->
			if s.substring(0, t.length) is t then return
			throw new Error "Expected token: " + t + " at " + s.substring 0, 50
		getBlankNode: (id) ->
			if @bnHash.exists id then return @bnHash.get id
			bn = @context.createBlankNode()
			@bnHash.set id, bn
			return bn
		skipWS: (s) ->
			while api.parsers.Turtle.isWhitespace.test s.charAt 0
				s = s.replace api.parsers.Turtle.initialWhitespace, ""
				if s.charAt(0) is "#" then s = s.replace api.parsers.Turtle.initialComment, ""
			return s

	api.parsers.Turtle.isWhitespace = new RegExp("^[ \t\r\n#]+", "")
	api.parsers.Turtle.initialWhitespace = new RegExp("^[ \t\r\n]+", "")
	api.parsers.Turtle.initialComment = new RegExp("^#[^\r\n]*", "")
	api.parsers.Turtle.simpleToken = new RegExp("^[^ \t\r\n]+", "")
	api.parsers.Turtle.simpleObjectToken = new RegExp("^[^ \t\r\n;,]+", "")
	api.parsers.Turtle.tokenInteger = new RegExp("^(-|\\+)?[0-9]+$", "")
	api.parsers.Turtle.tokenDouble = new RegExp("^(-|\\+)?(([0-9]+\\.[0-9]*[eE]{1}(-|\\+)?[0-9]+)|(\\.[0-9]+[eE]{1}(-|\\+)?[0-9]+)|([0-9]+[eE]{1}(-|\\+)?[0-9]+))$", "")
	api.parsers.Turtle.tokenDecimal = new RegExp("^(-|\\+)?[0-9]*\\.[0-9]+?$", "")

	api.parseNT = (doc, cb, base, filter, graph) -> return new api.parsers.NTriples(api).parse doc, cb, base, filter, graph
	api.parseNT = (doc, cb, base, filter) -> return new api.parsers.NTriples(api).process doc, cb, base, filter 
	api.parseTurtle = (doc, cb, base, filter, graph) -> return new api.parsers.Turtle(api).parse doc, cb, base, filter, graph
	api.processTurtle = (doc, cb, base, filter) -> return new api.parsers.Turtle(api).process doc, cb, base, filter


)(rdf)

# src/serializers.coffee
((api) ->
	if not api.serializers then api.serializers = {}

	api.serializers.NTriples = (context) ->
	api.serializers.NTriples.prototype = 
		serialize: (graph) -> return graph.toArray().join("\n")
	
	class api.serializers.Turtle
		constructor: (context) ->
			@context = context
			@createPrefixMap()
		context: null
		index: null
		lists: null
		prefixMap: null
		usedPrefixes: null
		nonAnonBNodes: null
		skipSubjects: null
		serialize: (graph) ->
			@initiate()
			graph = @suckLists graph
			_.forEach(graph, (t, i, s)->
				this.addTripleToIndex t, i, s
			, this)
			return @render()
		startsWith: (o, s, i) ->
			if i then return s.toLowerCase() is o.substring(0, s.length).toLowerCase()
			return s is o.substring 0, s.length
		contains: (a, o) ->
			return a.indexOf(o) >= 0
		remove: (a, obj) ->
			idx = a.indexOf obj
			if idx is -1 then return false
			a.splice idx, 1
			return true
		addTripleToIndex: (t, i, s) ->
			if t.object.interfaceName is "BlankNode"
				@nonAnonBNodes.set t.object.toString(), if @nonAnonBNodes.exists t.object.toString() then @nonAnonBNodes.get(t.object.toString()) + 1 else 1
			s1 = @shrink t.subject
			p = @shrink t.property, true
			if not @index.exists s1 then @index.set s1, new api.Hash
			if not @index.get(s1).exists p then @index.get(s1).set p, new Array
			@index.get(s1).get(p).push t.object
		anonBNode: (subject, indent) ->
			return @propertyObjectChain @index.get(subject), indent	
		createPrefixMap: ->
			m = @context.prefixes
			@prefixMap = new api.Hash
			@prefixMap.set m[k], k.concat(":") for k of m
		initiate: ->
			@index			= new api.Hash
			@usedPrefixes	= new Array
			@nonAnonBNodes	= new api.Hash
			@skipSubjects	= new Array
			@suckLists		= new api.Hash
		output: (o) ->
			if o.interfaceName is "NamedNode" then return @shrink o
			if o.interfaceName is "Literal" and o.datatype
				if o.datatype.equals(@context.resolve("xsd:integer")) or \
				o.datatype.equals(@context.resolve("xsd:double")) or \
				o.datatype.equals(@context.resolve("xsd:decimal")) or \
				o.datatype.equals(@context.resolve("xsd:boolean"))
					return o.value
				else
					return '"' + o.value + '"^^' + @shrink o.type
			return o.toNT()
		propertyObjectChain: (po, indent = 2) ->
			if not po then return
			out = ""
			properties = po.keys()
			properties.sort()
			if @contains properties, "a"
				@remove properties, "a"
				properties.unshift("a")
			_.forEach(properties, (property, pi, pa) ->
				out = out + (if pi > 0 then (new Array(indent+1)).join(" ") else "") + property + " "
				_.forEach(po.get(property), (o, oi, oa) ->
					oindent = ""
					if oa.length > 2
						oindent = "\n" + (new Array(indent + 2 + 1)).join(" ")
					if o.toString().charAt(0) is "_" and not @nonAnonBNodes.exists o.toString()
						if @lists.exists o.toNT()
							out = out + @renderList o.toNT, indent + 3
						else
							out = out + oindent + "[ " + @anonBNode(o.toString(), indent + 2 + 2) + oindent + (if oa.length is 1 then " " else "") + "]"
					else
						out = out + oindent + @output o
					if oa.length - 1 isnt oi
						if oa.length > 2
							out = out + "," + (new Array(indent + 2 + 2)).join(" ")
						else
							out = out + ", "
				, this)
				out = out + (if pa.length - 1 is pi then "" else ";\n")
			, this)
			return out
		render: ->
			out = new Array
			@skipSubjects = @nonAnonBNodes.keys()
			_.forEach(@nonAnonBNodes.keys(), (k, i, a) ->
				if @nonAnonBNodes.get(k) is 1 then @nonAnonBNodes.remove k
			, this)
			_.forEach(@index.keys(), (subject, $is, $as) ->
				single = ""
				if subject.charAt(0) is "_"
					if not @nonAnonBNodes.exists(subject) and not @contains(@skipSubjects, subject)
						if @lists.exists subject
							single = @renderList(subject, 2) + " " + @propertyObjectChain(@index.get subject)
						else
							single = "[ " + @anonBNode(subject, 2) + "\n]"
				else
					single = subject + " " + @propertyObjectChain @index.get subject
				if single.length > 0 then out.push single + " .\n"
			, this)
			if @usedPrefixes.length > 0
				invertedMap = new api.Hash
				_.forEach(@prefixMap.keys(), (k, i, h) ->
					if @contains @usedPrefixes, k then invertedMap.set @prefixMap.get(k), k
				, this)
				prefixes = invertedMap.keys()
				prefixes.sort()
				prefixes.reverse()
				out.unshift("")
				_.forEach(prefixes, (s, i, a) ->
					out.unshift "@prefix " + s + " <" + invertedMap.get(s) + "> ."
				, this)
			return out.join("\n")
		renderList: (o, indent) ->
			list = new Array
			_.forEach(@lists.get(o), (n, i, a) -> 
				list.push(@output(n))
			, this)
			lis = new Array
			liststring = ""
			while list.length > 0
				li = list.shift()
				if liststring.length + li.length < 75
					liststring = liststring.concat(li + " ")
				else
					lis.push(liststring)
					liststring = li + " "
			lis.push(liststring)
			nl = if lis.length is 1 then " " else "\n" + (new Array indent).join(" ")
			return "(" + nl + lis.join(nl) + (if lis.length is 1 then "" else "\n") + ")"
		shrink: (n, property = false) ->
			if property and n.equals api.serializers.Turtle.RDF_TYPE then return "a"
			if n.equals api.serializers.Turtle.RDF_NIL then return "()"
			_g = 0
			_g1 = @prefixMap.keys()
			while _g < _g1.length
				i = _g1[_g]
				++_g
				if @startsWith n.toString(), i
					if not @contains @usedPrefixes, i then @usedPrefixes.push i
					return n.toString().replace i, @prefixMap.get i
			return n.toNT()
		suckLists: (graph) ->
			sFilter = (n) -> return (t, i, s) -> return t.subject.equals n
			pFilter = (n) -> return (t, i, s) -> return t.property.equals n
			poFilter = (p, o) -> return (t, i, s) -> return t.property.equals(p) and t.object.equals(o)
			tFilter = (a) -> return (t, i, s) -> return not (t.subject.equals(a.subject) and t.property.equals(a.property) and t.object.equals(a.object))
			members = graph.filter((t, i, s) ->
				return t.property.equals(api.serializers.Turtle.RDF_FIRST) or t.property.equals(api.serializers.Turtle.RDF_REST)
			)
			_.forEach(members, (t, i, s) ->
				graph = graph.filter tFilter t
			)
			ends = members.filter((t, i, s) -> return t.object.equals api.serializers.Turtle.RDF_NIL)
			_.forEach(ends, (n, i, s) ->
				tmplist = new Array
				q = n
				start = null
				while q isnt null
					start = q.subject
					tmplist.unshift(members.filter(sFilter start).filter(pFilter api.serializers.Turtle.RDF_FIRST).toArray().pop().object)
					members = members.filter((t, i1, s1) -> return not t.subject.equals start)
					q = members.filter(poFilter api.serializers.Turtle.RDF_REST, start).toArray().pop()
				@lists.set start.toNT(), tmplist
			, this)
			return graph
	api.serializers.Turtle.NS_RDF = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	api.serializers.Turtle.RDF_TYPE = api.createNamedNode api.serializers.Turtle.NS_RDF + "type"
	api.serializers.Turtle.RDF_RDF = api.createNamedNode api.serializers.Turtle.NS_RDF + "RDF"
	api.serializers.Turtle.RDF_FIRST = api.createNamedNode api.serializers.Turtle.NS_RDF + "first"
	api.serializers.Turtle.RDF_REST = api.createNamedNode api.serializers.Turtle.NS_RDF + "rest"
	api.serializers.Turtle.RDF_NIL = api.createNamedNode api.serializers.Turtle.NS_RDF + "nil"

	api.nt		= (graph) -> return new api.serializers.NTriples(api).serialize graph
	api.turtle	= (graph) -> return new api.serializers.Turtle(api).serialize graph
)(rdf)

# src/filters.coffee
((api)->
	api.filters = 
		s: (s) ->
			if _.isArray s then return (t) ->
				for i in s
					if t.s.equals s then return true
				return false
			return (t) -> return t.s.equals s
		p: (p) ->
			if _.isArray p then return (t) ->
				for i in p
					if t.p.equals i then return true
				return false
			return (t) -> return t.p.equals p
		o: (o) ->
			if _.isArray o then return (t) ->
				for i in o
					if t.o.equals i then return true
				return false
			return (t) -> return t.o.equals o
		sp: (s, p) ->
			if not _.isArray s then s = [s]
			if not _.isArray p then p = [p]
			return (t) ->
				for sub in s
					for prop in p
						if t.p.equals(prop) and t.s.equals(sub) then return true
				return false
		so: (s, o) ->
			if not _.isArray s then s = [s]
			if not _.isArray o then o = [o]
			return (t) ->
				for sub in s
					for obj in o
						if t.s.equals(sub) and t.o.equals(obj) then return true
				return false
		po: (p, o) ->
			if not _.isArray p then p = [p]
			if not _.isArray o then o = [o]
			return (t) ->
				for prop in p
					for obj in o
						if t.p.equals(prop) and t.o.equals(obj) then return true
				return false
		spo: (s, p, o) ->
			if not _.isArray s then s = [s]
			if not _.isArray p then p = [p]
			if not _.isArray o then o = [o]
			return (t) ->
				for sub in s
					for prop in p
						for obj in o
							if t.s.equals(sub) and t.p.equals(prop) and t.o.equals(obj) then return true
				return false
		describes: (o) ->
			if _.isArray o then return (t) ->
				for noun in o
					if t.s.equals(noun) or t.o.equals(noun) then return true
				return false
			return (t) -> return t.s.equals(o) or t.o.equals(o)
		type: (o) ->
			RDF_TYPE = api.resolve("rdf:type")
			if _.isArray o then return (t) ->
				for i in o
					if t.p.equals(RDF_TYPE) and t.o.equals(i) then return true
				return false
			return (t) -> t.p.equals(RDF_TYPE) and t.o.equals(o)
		constrainedTriple: ->
			return (t) ->
				return (t.s.interfaceName is 'NamedNode' or t.s.interfaceName is 'BlankNode') and t.p.interfaceName is 'NamedNode'
		link: ->
			return (t) ->
				return t.s.interfaceName is 'NamedNode' and t.p.interfaceName is 'NamedNode' and t.o.interfaceName is 'NamedNode'
	
	api.filterCount = (g, f) ->
		c = 0
		_.forEach(g, (t) -> f(t) and ++c)
		return c
	api.isOldSchool = (g) ->
		return g.every api.filters.constrainedTriple()
	api.links = (g) ->
		return g.filter api.filters.link()


)(rdf)

# src/basegraph.coffee
((api) ->
	api.BaseGraph = api.Graph
	class api.Graph
		constructor: (a) ->
			_.extend(this, new api.BaseGraph a)
		_distinct: (a) ->
			o = new api.Hash
			for i in @_graph
				if not o.exists i[a].h()
					o.set i[a].h(), i[a]
			console.log o
			return o.toArray()
		subjects: 	-> return @_distinct 's'
		predicates:	-> return @_distinct 'p'
		objects:	-> return @_distinct 's'
		isGround:	-> return @every((t) -> return not(t.s.interfaceName is "BlankNode" or t.p.interfaceName is "BlankNode" or t.o.interfaceName is "BlankNode"))
)(rdf)

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

# src/sugar.coffee
((api) ->
	api.log = (o) ->
		console.log o
	api.ref = (v) -> 
		return if v? then @createNamedNode @iri v else @createBlankNode
	api.iri = (i) -> return @createIRI if o = @resolve(i)? then o else i
	api.node = (v, t) ->
		if t? then return @literal v, t
		unless v? then return @createBlankNode()
		if typeof v is "string" and v.indexOf(":") >= 0 then return @ref v
		return @literal v
)(rdf)

# src/prefixes.coffee
((api) ->
	prefixes = 
		owl: "http://www.w3.org/2002/07/owl#"
		rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		rdfs: "http://www.w3.org/2000/01/rdf-schema#"
		rdfa: "http://www.w3.org/ns/rdfa#"
		xhv: "http://www.w3.org/1999/xhtml/vocab#"
		xml: "http://www.w3.org/XML/1998/namespace"
		xsd: "http://www.w3.org/2001/XMLSchema#"
		grddl: "http://www.w3.org/2003/g/data-view#"
		powder: "http://www.w3.org/2007/05/powder#"
		powders: "http://www.w3.org/2007/05/powder-s#"
		rif: "http://www.w3.org/2007/rif#"
		atom: "http://www.w3.org/2005/Atom/"
		xhtml: "http://www.w3.org/1999/xhtml#"
		formats: "http://www.w3.org/ns/formats/"
		xforms: "http://www.w3.org/2002/xforms/"
		xhtmlvocab: "http://www.w3.org/1999/xhtml/vocab/"
		xpathfn: "http://www.w3.org/2005/xpath-functions#"
		http: "http://www.w3.org/2006/http#"
		link: "http://www.w3.org/2006/link#"
		time: "http://www.w3.org/2006/time#"
		acl: "http://www.w3.org/ns/auth/acl#"
		cert: "http://www.w3.org/ns/auth/cert#"
		rsa: "http://www.w3.org/ns/auth/rsa#"
		crypto: "http://www.w3.org/2000/10/swap/crypto#"
		list: "http://www.w3.org/2000/10/swap/list#"
		log: "http://www.w3.org/2000/10/swap/log#"
		math: "http://www.w3.org/2000/10/swap/math#"
		os: "http://www.w3.org/2000/10/swap/os#"
		string: "http://www.w3.org/2000/10/swap/string#"
		doc: "http://www.w3.org/2000/10/swap/pim/doc#"
		contact: "http://www.w3.org/2000/10/swap/pim/contact#"
		p3p: "http://www.w3.org/2002/01/p3prdfv1#"
		swrl: "http://www.w3.org/2003/11/swrl#"
		swrlb: "http://www.w3.org/2003/11/swrlb#"
		exif: "http://www.w3.org/2003/12/exif/ns#"
		earl: "http://www.w3.org/ns/earl#"
		ma: "http://www.w3.org/ns/ma-ont#"
		sawsdl: "http://www.w3.org/ns/sawsdl#"
		sd: "http://www.w3.org/ns/sparql-service-description#"
		skos: "http://www.w3.org/2004/02/skos/core#"
		fresnel: "http://www.w3.org/2004/09/fresnel#"
		gen: "http://www.w3.org/2006/gen/ont#"
		timezone: "http://www.w3.org/2006/timezone#"
		skosxl: "http://www.w3.org/2008/05/skos-xl#"
		org: "http://www.w3.org/ns/org#"
		ical: "http://www.w3.org/2002/12/cal/ical#"
		wgs84: "http://www.w3.org/2003/01/geo/wgs84_pos#"
		vcard: "http://www.w3.org/2006/vcard/ns#"
		turtle: "http://www.w3.org/2008/turtle#"
		pointers: "http://www.w3.org/2009/pointers#"
		dcat: "http://www.w3.org/ns/dcat#"
		imreg: "http://www.w3.org/2004/02/image-regions#"
		rdfg: "http://www.w3.org/2004/03/trix/rdfg-1/"
		swp: "http://www.w3.org/2004/03/trix/swp-2/"
		rei: "http://www.w3.org/2004/06/rei#"
		wairole: "http://www.w3.org/2005/01/wai-rdf/GUIRoleTaxonomy#"
		states: "http://www.w3.org/2005/07/aaa#"
		wn20schema: "http://www.w3.org/2006/03/wn/wn20/schema/"
		httph: "http://www.w3.org/2007/ont/httph#"
		act: "http://www.w3.org/2007/rif-builtin-action#"
		common: "http://www.w3.org/2007/uwa/context/common.owl#"
		dcn: "http://www.w3.org/2007/uwa/context/deliverycontext.owl#"
		hard: "http://www.w3.org/2007/uwa/context/hardware.owl#"
		java: "http://www.w3.org/2007/uwa/context/java.owl#"
		loc: "http://www.w3.org/2007/uwa/context/location.owl#"
		net: "http://www.w3.org/2007/uwa/context/network.owl#"
		push: "http://www.w3.org/2007/uwa/context/push.owl#"
		soft: "http://www.w3.org/2007/uwa/context/software.owl#"
		web: "http://www.w3.org/2007/uwa/context/web.owl#"
		content: "http://www.w3.org/2008/content#"
		vs: "http://www.w3.org/2003/06/sw-vocab-status/ns#"
		air: "http://dig.csail.mit.edu/TAMI/2007/amord/air#"
		ex: "http://example.org/"
		dc: "http://purl.org/dc/terms/"
		dc11: "http://purl.org/dc/elements/1.1/"
		dctype: "http://purl.org/dc/dcmitype/"
		foaf: "http://xmlns.com/foaf/0.1/"
		cc: "http://creativecommons.org/ns#"
		opensearch: "http://a9.com/-/spec/opensearch/1.1/"
		'void': "http://rdfs.org/ns/void#"
		sioc: "http://rdfs.org/sioc/ns#"
		sioca: "http://rdfs.org/sioc/actions#"
		sioct: "http://rdfs.org/sioc/types#"
		lgd: "http://linkedgeodata.org/vocabulary#"
		moat: "http://moat-project.org/ns#"
		days: "http://ontologi.es/days#"
		giving: "http://ontologi.es/giving#"
		lang: "http://ontologi.es/lang/core#"
		like: "http://ontologi.es/like#"
		status: "http://ontologi.es/status#"
		og: "http://opengraphprotocol.org/schema/"
		protege: "http://protege.stanford.edu/system#"
		dady: "http://purl.org/NET/dady#"
		uri: "http://purl.org/NET/uri#"
		audio: "http://purl.org/media/audio#"
		video: "http://purl.org/media/video#"
		gridworks: "http://purl.org/net/opmv/types/gridworks#"
		hcterms: "http://purl.org/uF/hCard/terms/"
		bio: "http://purl.org/vocab/bio/0.1/"
		cs: "http://purl.org/vocab/changeset/schema#"
		geographis: "http://telegraphis.net/ontology/geography/geography#"
		doap: "http://usefulinc.com/ns/doap#"
		daml: "http://www.daml.org/2001/03/daml+oil#"
		geonames: "http://www.geonames.org/ontology#"
		sesame: "http://www.openrdf.org/schema/sesame#"
		cv: "http://rdfs.org/resume-rdf/"
		wot: "http://xmlns.com/wot/0.1/"
		media: "http://purl.org/microformat/hmedia/"
		ctag: "http://commontag.org/ns#"

	api.prefixes.addAll prefixes
)(rdf)

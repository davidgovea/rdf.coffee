
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

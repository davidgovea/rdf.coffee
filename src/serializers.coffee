
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
			graph.forEach((t, i, s) =>
				@.addTripleToIndex t, i, s
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
			@lists			= new api.Hash
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
			members.forEach((t, i, s) ->
				graph = graph.filter tFilter t
			)
			ends = members.filter((t, i, s) -> return t.object.equals api.serializers.Turtle.RDF_NIL)
			ends.forEach((n, i, s) ->
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


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

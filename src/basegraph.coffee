
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

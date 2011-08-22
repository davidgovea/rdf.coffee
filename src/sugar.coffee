
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


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
			_.forEach(@keys, (k) ->
				a.push @get k
			, this)
			return a
		toString: -> return JSON.stringify @h
)(rdf)


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

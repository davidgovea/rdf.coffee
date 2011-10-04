MINIFY := uglifyjs


all:
	mkdir lib -p
	cat src/interfaces.coffee src/hash.coffee src/iri.coffee src/parsers.coffee src/serializers.coffee src/filters.coffee src/basegraph.coffee src/converter.coffee src/sugar.coffee src/prefixes.coffee > lib/rdf.coffee
	coffee -c lib/rdf.coffee
	${MINIFY} -o lib/rdf.min.js lib/rdf.js

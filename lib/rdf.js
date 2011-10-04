(function() {
  var global;
  var __hasProp = Object.prototype.hasOwnProperty;
  global = typeof exports !== "undefined" && exports !== null ? exports : this;
  global.rdf = (function() {
    var env, itemtype, key, rdf, rp, x, xsd, _i, _len, _ref;
    rdf = {};
    rdf.encodeString = function(s) {
      var chr, code, hex, i, low, out, skip, _g, _g1;
      out = "";
      skip = false;
      _g1 = 0;
      _g = s.length;
      while (_g1 < _g) {
        i = _g1++;
        if (!skip) {
          code = s.charCodeAt(i);
          if (55296 <= code && code <= 56319) {
            low = s.charCodeAt(i + 1);
            chr = (code - 55296) * 1024 + (low - 56320) + 65536;
            skip = true;
          }
          if (code > 1114111) {
            throw new Error("Char out of range");
          }
          hex = "00000000".concat((new Number(code)).toString(16).toUpperCase());
          if (code >= 65536) {
            out += "\\U" + hex.slice(-8);
          } else {
            if (code >= 127 || code <= 31) {
              switch (code) {
                case 9:
                  out += "\\t";
                  break;
                case 10:
                  out += "\\n";
                  break;
                case 13:
                  out += "\\r";
                  break;
                default:
                  out += "\\u" + hex.slice(-4);
              }
            } else {
              switch (code) {
                case 34:
                  out += '\\"';
                  break;
                case 92:
                  out += "\\\\";
                  break;
                default:
                  out += s.charAt(i);
              }
            }
          }
        } else {
          skip = !skip;
        }
      }
      return out;
    };
    rdf.BlankNode = (function() {
      function BlankNode() {
        this.nominalValue = 'b'.concat(++rdf.BlankNode.NEXTID);
        this.interfaceName = 'BlankNode';
      }
      BlankNode.prototype.valueOf = function() {
        return this.nominalValue;
      };
      BlankNode.prototype.equals = function(o) {
        if (!o.hasOwnProperty('interfaceName')) {
          return this.nominalValue === o;
        }
        if (o.interfaceName === this.interfaceName) {
          return this.nominalValue === o.nominalValue;
        } else {
          return false;
        }
      };
      BlankNode.prototype.toString = function() {
        return '_:'.concat(this.nominalValue);
      };
      BlankNode.prototype.toNT = function() {
        return rdf.encodeString(this.toString());
      };
      BlankNode.prototype.h = function() {
        return this.nominalValue;
      };
      return BlankNode;
    })();
    rdf.BlankNode.NEXTID = 0;
    rdf.NamedNode = (function() {
      function NamedNode(iri) {
        this.nominalValue = iri;
        this.interfaceName = 'NamedNode';
      }
      NamedNode.prototype.valueOf = function() {
        return this.nominalValue;
      };
      NamedNode.prototype.equals = function(o) {
        return this.nominalValue === o;
        if (o.interfaceName === this.interfaceName) {
          return this.nominalValue === o.nominalValue;
        } else {
          return false;
        }
      };
      NamedNode.prototype.toString = function() {
        return this.nominalValue.toString();
      };
      NamedNode.prototype.toNT = function() {
        return '<' + rdf.encodeString(this.toString()) + '>';
      };
      NamedNode.prototype.h = function() {
        return this.nominalValue;
      };
      return NamedNode;
    })();
    rdf.Literal = (function() {
      function Literal(value, language, datatype, nativ) {
        if (typeof language === 'string' && language[0] === '@') {
          language = language.slice(1);
        }
        this.nominalValue = value;
        this.language = language;
        this.datatype = datatype;
        this.h = function() {
          return language + '|' + (datatype ? datatype.toString() : '') + '|' + value.toString();
        };
        this.valueOf = function() {
          if (nativ === null) {
            return this.nominalValue;
          } else {
            return nativ;
          }
        };
        this.interfaceName = 'Literal';
      }
      Literal.prototype.equals = function(o) {
        if (!o.hasOwnProperty('interfaceName')) {
          return this.valueOf() === o;
        }
        if (o.interfaceName !== this.interfaceName) {
          return false;
        }
        return this.h === o.h();
      };
      Literal.prototype.toString = function() {
        return this.nominalValue.toString();
      };
      Literal.prototype.toNT = function() {
        var s;
        s = '"' + rdf.encodeString(this.nominalValue) + '"';
        if (this.language) {
          return s.concat('@' + this.language);
        }
        if (this.datatype) {
          return s.concat('^^' + this.datatype.toNT());
        }
        return s;
      };
      return Literal;
    })();
    rdf.Triple = (function() {
      function Triple(s, p, o) {
        this.subject = this.s = s;
        this.property = this.p = p;
        this.object = this.o = o;
      }
      Triple.prototype.equals = function(t) {
        return this.s.equals(t.s) && this.p.equals(t.p) && this.o.equals(t.o);
      };
      Triple.prototype.toString = function() {
        return this.s.toNT() + " " + this.p.toNT() + " " + this.o.toNT() + " .";
      };
      return Triple;
    })();
    rdf.Graph = (function() {
      function Graph(a) {
        this._graph = [];
        this._spo = {};
        if (a != null) {
          this.addArray(a);
        }
      }
      Graph.prototype.length = function() {
        return this._graph.length;
      };
      Graph.prototype.add = function(t) {
        this._spo[t.s.h()] || (this._spo[t.s.h()] = {});
        this._spo[t.s.h()][t.p.h()] || (this._spo[t.s.h()][t.p.h()] = {});
        if (!this._spo[t.s.h()][t.p.h()][t.o.h()]) {
          this._spo[t.s.h()][t.p.h()][t.o.h()] = t;
          this._graph.push(t);
          _.forEach(this.actions, function(a) {
            return a.run(t);
          });
        }
        return this;
      };
      Graph.prototype.addArray = function(a) {
        var b, g;
        if (_.isArray(a)) {
          g = this;
          b = _.forEach(a, function(t) {
            return g.add(t);
          });
        }
        return this;
      };
      Graph.prototype.remove = function(t) {
        this._spo[t.s.h()] && this._spo[t.s.h()][t.p.h()] && this._spo[t.s.h()][t.p.h()][t.o.h()] && (delete this._spo[t.s.h()][t.p.h()][t.o.h()] && this._graph.splice(_.indexOf(this._graph, t), 1));
        return this;
      };
      Graph.prototype.removeMatches = function(s, p, o) {
        var i, r, _i, _len;
        s = arguments[0] === void 0 ? null : s;
        p = arguments[1] === void 0 ? null : p;
        o = arguments[2] === void 0 ? null : o;
        r = [];
        _.forEach(this, function(t, g) {
          return (s === null || t.s.equals(s)) && (p === null || t.p.equals(p)) && (o === null || t.o.equals(o)) && r.push(t);
        });
        for (_i = 0, _len = r.length; _i < _len; _i++) {
          i = r[_i];
          this.remove(i);
        }
        return this;
      };
      Graph.prototype.toArray = function() {
        return this._graph.slice(0);
      };
      Graph.prototype.some = function(cb) {
        return _.some(this._graph, cb);
      };
      Graph.prototype.every = function(cb) {
        return _.every(this._graph, cb);
      };
      Graph.prototype.filter = function(cb) {
        return new rdf.Graph(_.filter(this._graph, cb));
      };
      Graph.prototype.forEach = function(cb) {
        var g;
        g = this;
        return _.forEach(this._graph, function(t) {
          return cb(t, g);
        });
      };
      Graph.prototype.match = function(s, p, o, l) {
        var c;
        s = arguments[0] === void 0 ? null : s;
        p = arguments[1] === void 0 ? null : p;
        o = arguments[2] === void 0 ? null : o;
        l = arguments[3] === void 0 ? null : l;
        c = 0;
        if (l < 1) {
          l = -1;
        }
        return new rdf.Graph(_.filter(this._graph, function(t) {
          if (c === l) {
            return false;
          }
          return (s === null || t.s.equals(s)) && (p === null || t.p.equals(p)) && (o === null || t.o.equals(o)) && ++c;
        }));
      };
      Graph.prototype.merge = function(g) {
        return new rdf.Graph().addAll(this).addAll(g);
      };
      Graph.prototype.addAll = function(g) {
        return this.addArray(g.toArray());
      };
      Graph.prototype.actions = [];
      Graph.prototype.addActions = function(a, r) {
        if (r) {
          _.forEach(this, function(t, g) {
            return a.run(t, g);
          });
        }
        this.actions.push(a);
        return this;
      };
      return Graph;
    })();
    rdf.TripleAction = (function() {
      function TripleAction(test, action) {
        this.test = test;
        this.action = action;
      }
      TripleAction.prototype.run = function(t, g) {
        if (this.test(t)) {
          return this.action(t, g);
        }
      };
      return TripleAction;
    })();
    rdf.PrefixMap = (function() {
      function PrefixMap(i) {
        if (i != null) {
          this.addAll(i);
        }
      }
      PrefixMap.prototype.resolve = function(curie) {
        var index, prefix;
        index = curie.indexOf(":");
        if (index < 0 || curie.indexOf("//") >= 0) {
          return null;
        }
        prefix = curie.slice(0, index).toLowerCase();
        if (!this[prefix]) {
          return null;
        }
        return this[prefix].concat(curie.slice(++index));
      };
      PrefixMap.prototype.shrink = function(iri) {
        var pref, pval;
        for (pref in this) {
          pval = this[pref];
          if (iri.substr(0, pval.length) === pval) {
            return pref + ':' + iri.slice(pval.length);
          }
        }
        return iri;
      };
      PrefixMap.prototype.setDefault = function(iri) {
        return this[''] = iri;
      };
      PrefixMap.prototype.addAll = function(prefixes, override) {
        var p;
        for (p in prefixes) {
          if (!this[p] || override) {
            this[p] = prefixes[p];
          }
        }
        return this;
      };
      return PrefixMap;
    })();
    rdf.TermMap = (function() {
      function TermMap(i) {
        if (i != null) {
          this.addAll(i);
        }
      }
      TermMap.prototype.resolve = function(term) {
        if (this[term]) {
          return this[term];
        }
        if (this[""]) {
          return this[""].concat(term);
        }
        return null;
      };
      TermMap.prototype.shrink = function(iri) {
        var t;
        for (t in this) {
          if (this[t] === iri) {
            return t;
          }
        }
        return iri;
      };
      TermMap.prototype.setDefault = function(iri) {
        return this[''] = iri;
      };
      TermMap.prototype.addAll = function(terms, override) {
        var t;
        for (t in terms) {
          if (!this[t] || override) {
            this[t] = terms[t];
          }
        }
        return this;
      };
      return TermMap;
    })();
    rdf.Profile = (function() {
      function Profile(i) {
        if (i != null) {
          this.importProfile(i);
        }
      }
      Profile.prototype.prefixes = new rdf.PrefixMap;
      Profile.prototype.terms = new rdf.TermMap;
      Profile.prototype.resolve = function(tp) {
        if (tp.indexOf(":") >= 0) {
          return this.prefixes.resolve(tp);
        } else {
          return this.terms.resolve(tp);
        }
      };
      Profile.prototype.setDefaultVocabulary = function(iri) {
        return this.terms.setDefault(iri);
      };
      Profile.prototype.setDefaultPrefix = function(iri) {
        return this.prefixes.setDefault(iri);
      };
      Profile.prototype.setTerm = function(term, iri) {
        return this.terms[term] = iri;
      };
      Profile.prototype.setPrefix = function(prefix, iri) {
        return this.prefixes[prefix] = iri;
      };
      Profile.prototype.importProfile = function(profile, override) {
        if (!profile) {
          return this;
        }
        this.prefixes.addAll(profile.prefixes, override);
        this.terms.addAll(profile.terms, override);
        return this;
      };
      return Profile;
    })();
    rp = {
      terms: {},
      prefixes: {
        owl: "http://www.w3.org/2002/07/owl#",
        rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        rdfs: "http://www.w3.org/2000/01/rdf-schema#",
        rdfa: "http://www.w3.org/ns/rdfa#",
        xhv: "http://www.w3.org/1999/xhtml/vocab#",
        xml: "http://www.w3.org/XML/1998/namespace",
        xsd: "http://www.w3.org/2001/XMLSchema#"
      }
    };
    xsd = {};
    _ref = x = ['string', 'boolean', 'dateTime', 'date', 'time', 'int', 'double', 'float', 'decimal', 'integer', 'nonPositiveInteger', 'negativeInteger', 'long', 'int', 'short', 'byte', 'nonNegativeInteger', 'unsignedLong', 'unsignedInt', 'unsignedShort', 'unsignedByte', 'positiveInteger'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      itemtype = _ref[_i];
      xsd[itemtype] = rp.prefixes.xsd.concat(itemtype);
    }
    rdf.RDFEnvironment = (function() {
      function RDFEnvironment() {
        _.extend(this, new rdf.Profile(rp));
      }
      RDFEnvironment.prototype.createBlankNode = function() {
        return new rdf.BlankNode;
      };
      RDFEnvironment.prototype.createNamedNode = function(iri) {
        return new rdf.NamedNode(iri);
      };
      RDFEnvironment.prototype.createLiteral = function(value) {
        var dt, l, v;
        l = null;
        dt = arguments[2];
        v = value;
        if (arguments[1]) {
          if (arguments[1].hasOwnProperty('interfaceName')) {
            dt = arguments[1];
          } else {
            l = arguments[1];
          }
        }
        if (dt) {
          switch (dt.valueOf()) {
            case xsd.string:
              v = new String(v);
              break;
            case xsd['boolean']:
              v = (new Boolean(v === false ? false : v)).valueOf();
              break;
            case xsd['float']:
            case xsd.integer:
            case xsd['long']:
            case xsd['double']:
            case xsd.decimal:
            case xsd.nonPositiveInteger:
            case xsd.nonNegativeInteger:
            case xsd.negativeInteger:
            case xsd['int']:
            case xsd.unsignedLong:
            case xsd.positiveInteger:
            case xsd['short']:
            case xsd.unsignedInt:
            case xsd['byte']:
            case xsd.unsignedShort:
            case xsd.unsignedByte:
              v = (new Number(v)).valueOf();
              break;
            case xsd['date']:
            case xsd.time:
            case xsd.dateTime:
              v = new Date(v);
          }
        }
        return new rdf.Literal(value, l, dt, v);
      };
      RDFEnvironment.prototype.createTriple = function(s, p, o) {
        return new rdf.Triple(s, p, o);
      };
      RDFEnvironment.prototype.createGraph = function(a) {
        return new rdf.Graph(a);
      };
      RDFEnvironment.prototype.createAction = function(t, a) {
        return new rdf.TripleAction(t, a);
      };
      RDFEnvironment.prototype.createProfile = function(empty) {
        return new rdf.Profile(!empty ? this : null);
      };
      RDFEnvironment.prototype.createTermMap = function(empty) {
        return new rdf.TermMap(!empty ? this.terms : null);
      };
      RDFEnvironment.prototype.createPrefixMap = function(empty) {
        return new rdf.PrefixMap(!empty ? this.prefixes : null);
      };
      return RDFEnvironment;
    })();
    env = new rdf.RDFEnvironment;
    for (key in rdf) {
      if (!__hasProp.call(rdf, key)) continue;
      env[key] = rdf[key];
    }
    return rdf = env;
  })();
  (function(api) {
    return api.Hash = (function() {
      function Hash(p) {
        this.empty();
      }
      Hash.prototype.h = null;
      Hash.prototype.get = function(k) {
        return this.h[k];
      };
      Hash.prototype.set = function(k, v) {
        return this.h[k] = v;
      };
      Hash.prototype.empty = function() {
        return this.h = {};
      };
      Hash.prototype.exists = function(k) {
        return this.h.hasOwnProperty(k);
      };
      Hash.prototype.keys = function(proto) {
        var i, keys;
        keys = [];
        proto = !proto;
        for (i in this.h) {
          if (proto && Object.prototype[i]) {
            continue;
          }
          keys.push(i);
        }
        return keys;
      };
      Hash.prototype.remove = function(k) {
        var r;
        r = this.get(k);
        delete this.h[k];
        return r;
      };
      Hash.prototype.toArray = function() {
        var a;
        a = new Array;
        _.forEach(this.keys(), function(k) {
          return a.push(this.get(k));
        }, this);
        return a;
      };
      Hash.prototype.toString = function() {
        return JSON.stringify(this.h);
      };
      return Hash;
    })();
  })(rdf);
  (function(api) {
    var SCHEME_MATCH;
    SCHEME_MATCH = new RegExp("^[a-z0-9-.+]+:", "i");
    api.IRI = (function() {
      function IRI(iri) {
        this.value = iri;
      }
      IRI.prototype.toString = function() {
        return this.value;
      };
      IRI.prototype.defrag = function() {
        var i;
        i = this.value.indexOf("#");
        if (i < 0) {
          return this;
        } else {
          return new api.IRI(this.value.slice(0, i));
        }
      };
      IRI.prototype.isAbsolute = function() {
        return this.scheme() !== null && this.heirpart() !== null && this.fragment() === null;
      };
      IRI.prototype.toAbsolute = function() {
        if (this.scheme() === null && this.heirpart() === null) {
          throw new Error("IRI must have a scheme and a heirpart!");
        }
        return this.resolveReference(this.value).defrag();
      };
      IRI.prototype.authority = function() {
        var authority, heirpart, q;
        heirpart = this.heirpart();
        if (heirpart.substring(0, 2) !== "//") {
          return null;
        }
        authority = heirpart.slice(2);
        q = authority.indexOf("/");
        if (q >= 0) {
          return authority.substring(0, q);
        } else {
          return authority;
        }
      };
      IRI.prototype.fragment = function() {
        var i;
        i = this.value.indexOf("#");
        if (i < 0) {
          return null;
        } else {
          return this.value.slice(i);
        }
      };
      IRI.prototype.heirpart = function() {
        var heirpart, q, q2;
        heirpart = this.value;
        q = heirpart.indexOf("?");
        if (q >= 0) {
          heirpart = heirpart.substring(0, q);
        } else {
          q = heirpart.indexOf("#");
          if (q >= 0) {
            heirpart = heirpart.substring(0, q);
          }
        }
        q2 = this.scheme();
        if (q2 !== null) {
          heirpart = heirpart.slice(1 + q2.length);
        }
        return heirpart;
      };
      IRI.prototype.host = function() {
        var host, q;
        host = this.authority();
        q = host.indexOf("@");
        if (q >= 0) {
          host = host.slice(++q);
        }
        if (host.indexOf("[") === 0) {
          q = host.indexOf("]");
          if (q > 0) {
            return host.substring(0, q);
          }
        }
        q = host.lastIndexOf(":");
        if (q >= 0) {
          return host.substring(0, q);
        } else {
          return host;
        }
      };
      IRI.prototype.path = function() {
        var q;
        q = this.authority();
        if (q === null) {
          return this.heirpart();
        }
        return this.heirpart().slice(q.length + 2);
      };
      IRI.prototype.port = function() {
        var host, q;
        host = this.authority();
        q = host.indexOf("@");
        if (q >= 0) {
          host = host.slice(++q);
        }
        if (host.indexOf("[") === 0) {
          q = host.indexOf("]");
          if (q > 0) {
            return host.substring(0, q);
          }
        }
        q = host.lastIndexOf(":");
        if (q < 0) {
          return null;
        }
        host = host.slice(++q);
        if (host.length === 0) {
          return null;
        } else {
          return host;
        }
      };
      IRI.prototype.query = function() {
        var f, q;
        q = this.value.indexOf("?");
        if (q < 0) {
          return null;
        }
        f = this.value.indexOf("#");
        if (f < 0) {
          return this.value.slice(q);
        }
        return this.value.substring(q, f);
      };
      IRI.prototype.removeDotSegments = function(input) {
        var output, q;
        output = "";
        q = 0;
        while (input.length > 0) {
          if (input.substr(0, 3) === "../" || input.substr(0, 2) === "./") {
            input = input.slice(input.indexOf("/"));
          } else {
            if (input === "/.") {
              input = "/";
            } else {
              if (input.substr(0, 3) === "/./") {
                input = input.slice(2);
              } else {
                if (input.substr(0, 4) === "/../" || input === "/..") {
                  input = input === "/.." ? "/" : input.slice(3);
                  q = output.lastIndexOf("/");
                  output = q >= 0 ? output.substring(0, q) : "";
                } else {
                  if (input.substr(0, 2) === ".." || input.substr(0, 1) === ".") {
                    input = input.slice(input.indexOf("."));
                    q = input.indexOf(".");
                    if (q >= 0) {
                      input = input.slice(q);
                    }
                  } else {
                    if (input.substr(0, 1) === "/") {
                      output += "/";
                      input = input.slice(1);
                    }
                    q = input.indexOf("/");
                    if (q < 0) {
                      output += input;
                      input = "";
                    } else {
                      output += input.substring(0, q);
                      input = input.slice(q);
                    }
                  }
                }
              }
            }
          }
        }
        return output;
      };
      IRI.prototype.resolveReference = function(ref) {
        var T, q, q2, reference;
        reference = new api.IRI(ref.toString());
        T = {
          scheme: "",
          authority: "",
          path: "",
          query: "",
          fragment: ""
        };
        q = "";
        if (reference.scheme() !== null) {
          T.scheme = reference.scheme();
          q = reference.authority();
          T.authority += q !== null ? "//" + q : "";
          T.path = this.removeDotSegments(reference.path());
          q = reference.query();
          T.query += q !== null ? q : "";
        } else {
          q = reference.authority();
          if (q !== null) {
            T.authority = "//" + q;
            T.path = this.removeDotSegments(reference.path());
            q = reference.query();
            T.query += q !== null ? q : "";
          } else {
            q = reference.path();
            if (q === "" || q === null) {
              T.path = this.path();
              q = reference.query();
              if (q !== null) {
                T.query += q;
              } else {
                q = this.query();
                T.query += q !== null ? q : "";
              }
            } else {
              if (q.substring(0, 1) === "/") {
                T.path = this.removeDotSegments(q);
              } else {
                if (this.path() !== null) {
                  q2 = this.path().lastIndexOf("/");
                  if (q2 >= 0) {
                    T.path = this.path().substring(0, ++q2);
                  }
                  T.path += reference.path();
                } else {
                  T.path = "/" + q;
                }
                T.path = this.removeDotSegments(T.path);
              }
              q = reference.query();
              T.query += q !== null ? q : "";
            }
            q = this.authority();
            T.authority = q !== null ? "//" + q : "";
          }
          T.scheme = this.scheme();
        }
        q = reference.fragment();
        T.fragment = q !== null ? q : "";
        return new api.IRI(T.scheme + ":" + T.authority + T.path + T.query + T.fragment);
      };
      IRI.prototype.scheme = function() {
        var scheme;
        scheme = this.value.match(SCHEME_MATCH);
        if (scheme === null) {
          return null;
        } else {
          return scheme.shift().slice(0, -1);
        }
      };
      IRI.prototype.userInfo = function() {
        var authority, q;
        authority = this.authority();
        q = authority.indexOf("@");
        if (q < 0) {
          return null;
        } else {
          return authority.substring(0, q);
        }
      };
      return IRI;
    })();
    return api.createIRI = function(i) {
      return new api.IRI(i);
    };
  })(rdf);
  (function(api) {
    if (!api.parsers) {
      api.parsers = {};
    }
    api.parsers.u8 = new RegExp("\\\\U([A-F0-9]{8})", "g");
    api.parsers.u4 = new RegExp("\\\\u([A-F0-9]{4})", "g");
    api.parsers.hexToChar = function(hex) {
      var n, result;
      result = "";
      n = parseInt(hex, 16);
      if (n <= 65535) {
        result += String.fromCharCode(n);
      } else if (n <= 1114111) {
        n -= 65536;
        result += String.fromCharCode(55296 + (n >> 10), 56320 + (n & 1023));
      } else {
        throw new Error("code point isn't known: " + n);
      }
      return result;
    };
    api.parsers.decodeString = function(str) {
      str = str.replace(api.parsers.u8, function(matchstr, parens) {
        return api.parsers.hexToChar(parens);
      });
      str = str.replace(api.parsers.u4, function(matchstr, parens) {
        return api.parsers.hexToChar(parens);
      });
      str = str.replace(new RegExp("\\\\t", "g"), "\t");
      str = str.replace(new RegExp("\\\\n", "g"), "\n");
      str = str.replace(new RegExp("\\\\r", "g"), "\r");
      str = str.replace(new RegExp('\\\\"', "g"), '"');
      str = str.replace(new RegExp("\\\\\\\\", "g"), "\\");
      return str;
    };
    api.parsers.NTriples = (function() {
      function NTriples(context) {
        this.context = context;
        this.bnHash = new api.Hash;
      }
      NTriples.prototype.context = null;
      NTriples.prototype.quick = null;
      NTriples.prototype.bnHash = null;
      NTriples.prototype.graph = null;
      NTriples.prototype.filter = null;
      NTriples.prototype.processor = null;
      NTriples.prototype.base = null;
      NTriples.prototype.parse = function(toparse, cb, base, filter, graph) {
        this.graph = graph != null ? graph : this.context.createGraph();
        this.filter = filter;
        this.quick = false;
        this.base = base;
        this.internalParse(toparse);
        if (typeof cb === "function") {
          cb(this.graph);
        }
        return true;
      };
      NTriples.prototype.process = function(toparse, processor, base, filter) {
        this.processor = processor;
        this.filter = filter;
        this.quick = true;
        this.base = base;
        return this.internalParse(toparse);
      };
      NTriples.prototype.getBlankNode = function(id) {
        var bn;
        if (this.bnHash.exists(id)) {
          return this.bhHash.get(id);
        }
        bn = this.context.createBlankNode();
        this.bnHash.set(id, bn);
        return bn;
      };
      NTriples.prototype.internalParse = function(toparse) {
        var data, lines;
        data = new String(toparse);
        lines = data.split(api.parsers.NTriples.eolMatcher);
        return _.forEach(lines, function(a, b, c) {
          return this.readLine(a, b, c);
        }, this);
      };
      NTriples.prototype.negotiateLiteral = function(plain) {
        var lang, parts;
        if (plain.slice(-1) === '"') {
          return this.context.createLiteral(api.parsers.decodeString(plain.slice(1, -1)));
        }
        lang = plain.match(api.parsers.NTriples.trailingLanguage);
        if (lang !== null) {
          return this.context.createLiteral(api.parsers.decodeString(plain.slice(1, -1 - lang.shift().length)), lang.pop());
        }
        parts = plain.match(api.parsers.NTriples.typedLiteralMatcher);
        return this.context.createLiteral(api.parsers.decodeString(parts[1]), api.createNamedNode(parts.pop()));
      };
      NTriples.prototype.readLine = function(line, index, array) {
        var $use, o, p, s, spo, triple;
        if (api.parsers.NTriples.isComment.test(line) || api.parsers.NTriples.isEmptyLine.test(line)) {
          return;
        }
        line = line.replace(api.parsers.NTriples.initialWhitespace, "").replace(api.parsers.NTriples.trailingWhitespace, "");
        spo = line.split(api.parsers.NTriples.whitespace, 2);
        spo.push(line.replace(api.parsers.NTriples.objectMatcher, "$3"));
        if (spo[0].charAt(0) === "<") {
          s = this.context.createNamedNode(api.parsers.decodeString(spo[0].slice(1, -1)));
        } else {
          s = this.getBlankNode(spo[0].slice(2));
        }
        spo.shift();
        p = this.context.createNamedNode(spo.shift().slice(1, -1));
        switch (spo[0].charAt(0)) {
          case "<":
            o = this.context.createNamedNode(api.parsers.decodeString(spo[0].slice(1, -1)));
            break;
          case "_":
            o = this.getBlankNode(spo[0].slice(2));
            break;
          default:
            o = this.negotiateLiteral(spo[0]);
        }
        triple = this.context.createTriple(s, p, o);
        $use = true;
        if (this.filter != null) {
          $use = this.filter(triple, null, null);
        }
        if (!$use) {
          return;
        }
        if (this.quick) {
          return this.processor(triple);
        } else {
          return this.graph.add(triple);
        }
      };
      return NTriples;
    })();
    api.parsers.NTriples.isComment = new RegExp("^[ \t]*#", "");
    api.parsers.NTriples.isEmptyLine = new RegExp("^[ \t]*$", "");
    api.parsers.NTriples.initialWhitespace = new RegExp("^[ \t]+", "");
    api.parsers.NTriples.trailingWhitespace = new RegExp("[. \t]+$", "");
    api.parsers.NTriples.whitespace = new RegExp("[ \t]+", "");
    api.parsers.NTriples.objectMatcher = new RegExp("^([^ \t]+)[ \t]+([^ \t]+)[ \t]+(.*)$", "");
    api.parsers.NTriples.trailingLanguage = new RegExp("@([a-z]+[-a-z0-9]+)$", "");
    api.parsers.NTriples.typedLiteralMatcher = new RegExp('^"(.*)"(.{2})<([^>]+)>$', "");
    api.parsers.NTriples.eolMatcher = new RegExp("\r\n|\n|\r", "g");
    api.parsers.Turtle = (function() {
      function Turtle(context) {
        this.context = context;
        this.bnHash = new api.Hash;
      }
      Turtle.prototype.bnHash = null;
      Turtle.prototype.context = null;
      Turtle.prototype.filter = null;
      Turtle.prototype.processor = null;
      Turtle.prototype.quick = null;
      Turtle.prototype.graph = null;
      Turtle.prototype.base = null;
      Turtle.prototype.parse = function(doc, cb, base, filter, graph) {
        this.graph = graph != null ? graph : this.context.createGraph();
        this.filter = filter;
        this.quick = false;
        this.base = base;
        this.parseStatements(new String(doc));
        if (typeof cb === "function") {
          cb(this.graph);
        }
        return true;
      };
      Turtle.prototype.process = function(doc, processor, base, filter) {
        this.processor = processor;
        this.filter = filter;
        this.quick = true;
        this.base = base;
        return this.parseStatements(new String(doc));
      };
      Turtle.prototype.t = function() {
        return {
          o: null
        };
      };
      Turtle.prototype.parseStatements = function(s) {
        s = s.toString();
        while (s.length > 0) {
          s = this.skipWS(s);
          if (s.length === 0) {
            return true;
          }
          s = s.charAt(0) === "@" ? this.consumeDirective(s) : this.consumeStatement(s);
          this.expect(s, ".");
          s = this.skipWS(s.slice(1));
        }
        return true;
      };
      Turtle.prototype.add = function(t) {
        var $use;
        $use = true;
        if ((this.filter != null) && !this.filter(t)) {
          return;
        }
        if (this.quick) {
          return this.processor(t);
        } else {
          return this.graph.add(t);
        }
      };
      Turtle.prototype.consumeBlankNode = function(s, t) {
        t.o = this.context.createBlankNode();
        s = this.skipWS(s.slice(1));
        if (s.charAt(0) === "]") {
          return s.slice(1);
        }
        s = this.skipWS(this.consumePredicateObjectList(s, t));
        this.expect(s, "]");
        return this.skipWS(s.slice(1));
      };
      Turtle.prototype.consumeCollection = function(s, subject) {
        var cont, listject, o, token;
        subject.o = this.context.createBlankNode();
        listject = this.t();
        listject.o = subject.o;
        s = this.skipWS(s.slice(1));
        cont = s.charAt(0) !== ")";
        if (!cont) {
          subject.o = this.context.createNamedNode(this.context.resolve("rdf:nil"));
        }
        while (cont) {
          o = this.t();
          switch (s.charAt(0)) {
            case "[":
              s = this.consumeBlankNode(s, o);
              break;
            case "_":
              s = this.consumeKnownBlankNode(s, o);
              break;
            case "(":
              s = this.consumeCollection(s, o);
              break;
            case "<":
              s = this.consumeURI(s, o);
              break;
            case '"':
              s = this.consumeLiteral(s, o);
              break;
            default:
              token = s.match(api.parsers.Turtle.simpleObjectToken).shift();
              if (token.charAt(token.length - 1) === ")") {
                token = token.substring(0, token.length - 1);
              }
              if (token === "false" || token === "true") {
                o.o = this.context.createLiteral(token, this.context.createNamedNode(this.context.resolve("xsd:boolean")));
              } else if (token.indexOf(":") > -1) {
                o.o = this.context.resolve(token);
              } else if (api.parsers.Turtle.tokenInteger.test(token)) {
                o.o = this.context.createLiteral(token, this.context.createNamedNode(this.context.resolve("xsd:integer")));
              } else if (api.parsers.Turtle.tokenDouble.test(token)) {
                o.o = this.context.createLiteral(token, this.context.createNamedNode(this.context.resolve("xsd:double")));
              } else if (api.parsers.Turtle.tokenDecimal.test(token)) {
                o.o = this.context.createLiteral(token, this.context.createNamedNode(this.context.resolve("xsd:decimal")));
              } else {
                throw new Error("unrecognized token: " + token);
              }
              s = s.slice(token.length);
          }
          this.add(this.context.createTriple(listject.o, this.context.createNamedNode(this.context.resolve("rdf:first")), o.o));
          s = this.skipWS(s);
          cont = s.charAt(0) !== ")";
          if (cont) {
            this.add(this.context.createTriple(listject.o, this.context.createNamedNode(this.context.resolve("rdf:rest")), listject.o = this.context.createBlankNode()));
          } else {
            this.add(this.context.createTriple(listject.o, this.context.createNamedNode(this.context.resolve("rdf:rest")), this.context.createNamedNode(this.context.resolve("rdf.nil"))));
          }
        }
        return this.skipWS(s.slice(1));
      };
      Turtle.prototype.consumeDirective = function(s) {
        var p, prefix, prefixUri;
        p = 0;
        if (s.substring(1, 7) === "prefix") {
          s = this.skipWS(s.slice(7));
          p = s.indexOf(":");
          prefix = s.substring(0, p);
          s = this.skipWS(s.slice(++p));
          this.expect(s, "<");
          prefixUri = api.parsers.decodeString(s.substring(1, p = s.indexOf(">")));
          if (prefixUri !== "") {
            this.context.setPrefix(prefix, prefixUri);
          }
          s = this.skipWS(s.slice(++p));
        } else if (s.substring(1, 5) === "base") {
          s = this.skipWS(s.slice(5));
          this.expect(s, "<");
          this.base = this.context.createIRI(api.parsers.decodeString(s.substring(1, p = s.indexOf(">"))));
          s = this.skipWS(s.slice(++p));
        } else {
          throw new Error("Unknown directive: " + s.substring(0, 50));
        }
        return s;
      };
      Turtle.prototype.consumeKnownBlankNode = function(s, t) {
        var bname;
        this.expect(s("_:"));
        bname = s.slice(2).match(api.parsers.Turtle.simpleToken).shift();
        t.o = this.getBlankNode(bname);
        return s.slice(bname.length + 2);
      };
      Turtle.prototype.consumeLiteral = function(s, o) {
        var end, hunt, token, value;
        value = "";
        hunt = true;
        end = 0;
        if (s.substring(0, 3) === '"""') {
          end = 3;
          while (hunt) {
            end = s.indexOf('"""', end);
            if (hunt = s.charAt(end - 1) === "\\") {
              end++;
            }
          }
          value = s.substring(3, end);
          s = s.slice(value.length + 6);
        } else {
          while (hunt) {
            end = s.indexOf('"', end + 1);
            hunt = s.charAt(end - 1) === "\\";
          }
          value = s.substring(1, end);
          s = s.slice(value.length + 2);
        }
        value = api.parsers.decodeString(value);
        switch (s.charAt(0)) {
          case "@":
            token = s.match(api.parsers.Turtle.simpleObjectToken).shift();
            o.o = this.context.createLiteral(value, token.slice(1));
            s = s.slice(token.length);
            break;
          case "^":
            token = s.match(api.parsers.Turtle.simpleObjectToken).shift().slice(2);
            if (token.charAt(0) === "<") {
              o.o = this.context.createLiteral(value, this.context.createNamedNode(token.substring(1, token.length - 1)));
            } else {
              o.o = this.context.createLiteral(value, this.context.createNamedNode(this.context.resolve(token)));
            }
            s = s.slice(token.length + 2);
            break;
          default:
            o.o = this.context.createLiteral(value);
        }
        return s;
      };
      Turtle.prototype.consumeObjectList = function(s, subject, property) {
        var cont, o, token;
        cont = true;
        while (cont) {
          o = this.t();
          switch (s.charAt(0)) {
            case "[":
              s = this.consumeBlankNode(s, o);
              break;
            case "_":
              s = this.consumeKnownBlankNode(s, o);
              break;
            case "(":
              s = this.consumeCollection(s, o);
              break;
            case "<":
              s = this.consumeURI(s, o);
              break;
            case '"':
              s = this.consumeLiteral(s, o);
              break;
            default:
              token = s.match(api.parsers.Turtle.simpleObjectToken).shift();
              if (token.charAt(token.length - 1) === ".") {
                token = token.substring(0, token.length - 1);
              }
              if (token === "false" || token === "true") {
                o.o = this.context.createLiteral(token, this.context.createNamedNode(this.context.resolve("xsd:boolean")));
              } else if (token.indexOf(":") > -1) {
                o.o = this.context.createNamedNode(this.context.resolve(token));
              } else if (api.parsers.Turtle.tokenInteger.test(token)) {
                o.o = this.context.createLiteral(token, this.context.createNamedNode(this.context.resolve("xsd:integer")));
              } else if (api.parsers.Turtle.tokenDouble.test(token)) {
                o.o = this.context.createLiteral(token, this.context.createNamedNode(this.context.resolve("xsd:double")));
              } else if (api.parsers.Turtle.tokenDecimal.test(token)) {
                o.o = this.context.createLiteral(token, this.context.createNamedNode(this.context.resolve("xsd:decimal")));
              } else {
                throw new Error("unrecognized token: " + token);
              }
              s = s.slice(token.length);
          }
          this.add(this.context.createTriple(subject.o, property, o.o));
          s = this.skipWS(s);
          cont = s.charAt(0) === ",";
          if (cont) {
            s = this.skipWS(s.slice(1));
          }
        }
        return s;
      };
      Turtle.prototype.consumePredicateObjectList = function(s, subject) {
        var cont, next, predicate, property;
        cont = true;
        while (cont) {
          predicate = s.match(api.parsers.Turtle.simpleToken).shift();
          property = null;
          if (predicate === "a") {
            property = this.context.createNamedNode(this.context.resolve("rdf:type"));
          } else {
            switch (predicate.charAt(0)) {
              case "<":
                property = this.context.createNamedNode(api.parsers.decodeString(predicate.substring(1, predicate.indexOf(">"))));
                break;
              default:
                property = this.context.createNamedNode(this.context.resolve(predicate));
            }
          }
          s = this.skipWS(s.slice(predicate.length));
          s = this.consumeObjectList(s, subject, property);
          cont = s.charAt(0) === ";";
          if (cont) {
            s = this.skipWS(s.slice(1));
            next = s.charAt(0);
            if (next === "." || next === "]") {
              cont = false;
            }
          }
        }
        return s;
      };
      Turtle.prototype.consumeQName = function(s, t) {
        var qname;
        qname = s.match(api.parsers.Turtle.simpleToken).shift();
        t.o = this.context.createNamedNode(this.context.resolve(qname));
        return s.slice(qname.length);
      };
      Turtle.prototype.consumeStatement = function(s) {
        var t;
        t = this.t();
        switch (s.charAt(0)) {
          case "[":
            s = this.consumeBlankNode(s, t);
            if (s.charAt(0) === ".") {
              return s;
            }
            break;
          case "_":
            s = this.consumeKnownBlankNode(s, t);
            break;
          case "(":
            s = this.consumeCollection(s, t);
            break;
          case "<":
            s = this.consumeURI(s, t);
            break;
          default:
            s = this.consumeQName(s, t);
        }
        s = this.consumePredicateObjectList(this.skipWS(s), t);
        return s;
      };
      Turtle.prototype.consumeURI = function(s, t) {
        var p;
        this.expect(s, "<");
        p = 0;
        t.o = api.parsers.decodeString(s.substring(1, p = s.indexOf(">")));
        if (this.base) {
          t.o = this.base.resolveReference(t.o);
        }
        t.o = this.context.createNamedNode(t.o);
        return s.slice(++p);
      };
      Turtle.prototype.expect = function(s, t) {
        if (s.substring(0, t.length) === t) {
          return;
        }
        throw new Error("Expected token: " + t + " at " + s.substring(0, 50));
      };
      Turtle.prototype.getBlankNode = function(id) {
        var bn;
        if (this.bnHash.exists(id)) {
          return this.bnHash.get(id);
        }
        bn = this.context.createBlankNode();
        this.bnHash.set(id, bn);
        return bn;
      };
      Turtle.prototype.skipWS = function(s) {
        while (api.parsers.Turtle.isWhitespace.test(s.charAt(0))) {
          s = s.replace(api.parsers.Turtle.initialWhitespace, "");
          if (s.charAt(0) === "#") {
            s = s.replace(api.parsers.Turtle.initialComment, "");
          }
        }
        return s;
      };
      return Turtle;
    })();
    api.parsers.Turtle.isWhitespace = new RegExp("^[ \t\r\n#]+", "");
    api.parsers.Turtle.initialWhitespace = new RegExp("^[ \t\r\n]+", "");
    api.parsers.Turtle.initialComment = new RegExp("^#[^\r\n]*", "");
    api.parsers.Turtle.simpleToken = new RegExp("^[^ \t\r\n]+", "");
    api.parsers.Turtle.simpleObjectToken = new RegExp("^[^ \t\r\n;,]+", "");
    api.parsers.Turtle.tokenInteger = new RegExp("^(-|\\+)?[0-9]+$", "");
    api.parsers.Turtle.tokenDouble = new RegExp("^(-|\\+)?(([0-9]+\\.[0-9]*[eE]{1}(-|\\+)?[0-9]+)|(\\.[0-9]+[eE]{1}(-|\\+)?[0-9]+)|([0-9]+[eE]{1}(-|\\+)?[0-9]+))$", "");
    api.parsers.Turtle.tokenDecimal = new RegExp("^(-|\\+)?[0-9]*\\.[0-9]+?$", "");
    api.parseNT = function(doc, cb, base, filter, graph) {
      return new api.parsers.NTriples(api).parse(doc, cb, base, filter, graph);
    };
    api.parseNT = function(doc, cb, base, filter) {
      return new api.parsers.NTriples(api).process(doc, cb, base, filter);
    };
    api.parseTurtle = function(doc, cb, base, filter, graph) {
      return new api.parsers.Turtle(api).parse(doc, cb, base, filter, graph);
    };
    return api.processTurtle = function(doc, cb, base, filter) {
      return new api.parsers.Turtle(api).process(doc, cb, base, filter);
    };
  })(rdf);
  (function(api) {
    if (!api.serializers) {
      api.serializers = {};
    }
    api.serializers.NTriples = function(context) {};
    api.serializers.NTriples.prototype = {
      serialize: function(graph) {
        return graph.toArray().join("\n");
      }
    };
    api.serializers.Turtle = (function() {
      function Turtle(context) {
        this.context = context;
        this.createPrefixMap();
      }
      Turtle.prototype.context = null;
      Turtle.prototype.index = null;
      Turtle.prototype.lists = null;
      Turtle.prototype.prefixMap = null;
      Turtle.prototype.usedPrefixes = null;
      Turtle.prototype.nonAnonBNodes = null;
      Turtle.prototype.skipSubjects = null;
      Turtle.prototype.serialize = function(graph) {
        this.initiate();
        graph = this.suckLists(graph);
        _.forEach(graph, function(t, i, s) {
          return this.addTripleToIndex(t, i, s);
        }, this);
        return this.render();
      };
      Turtle.prototype.startsWith = function(o, s, i) {
        if (i) {
          return s.toLowerCase() === o.substring(0, s.length).toLowerCase();
        }
        return s === o.substring(0, s.length);
      };
      Turtle.prototype.contains = function(a, o) {
        return a.indexOf(o) >= 0;
      };
      Turtle.prototype.remove = function(a, obj) {
        var idx;
        idx = a.indexOf(obj);
        if (idx === -1) {
          return false;
        }
        a.splice(idx, 1);
        return true;
      };
      Turtle.prototype.addTripleToIndex = function(t, i, s) {
        var p, s1;
        if (t.object.interfaceName === "BlankNode") {
          this.nonAnonBNodes.set(t.object.toString(), this.nonAnonBNodes.exists(t.object.toString()) ? this.nonAnonBNodes.get(t.object.toString()) + 1 : 1);
        }
        s1 = this.shrink(t.subject);
        p = this.shrink(t.property, true);
        if (!this.index.exists(s1)) {
          this.index.set(s1, new api.Hash);
        }
        if (!this.index.get(s1).exists(p)) {
          this.index.get(s1).set(p, new Array);
        }
        return this.index.get(s1).get(p).push(t.object);
      };
      Turtle.prototype.anonBNode = function(subject, indent) {
        return this.propertyObjectChain(this.index.get(subject), indent);
      };
      Turtle.prototype.createPrefixMap = function() {
        var k, m, _results;
        m = this.context.prefixes;
        this.prefixMap = new api.Hash;
        _results = [];
        for (k in m) {
          _results.push(this.prefixMap.set(m[k], k.concat(":")));
        }
        return _results;
      };
      Turtle.prototype.initiate = function() {
        this.index = new api.Hash;
        this.usedPrefixes = new Array;
        this.nonAnonBNodes = new api.Hash;
        this.skipSubjects = new Array;
        return this.suckLists = new api.Hash;
      };
      Turtle.prototype.output = function(o) {
        if (o.interfaceName === "NamedNode") {
          return this.shrink(o);
        }
        if (o.interfaceName === "Literal" && o.datatype) {
          if (o.datatype.equals(this.context.resolve("xsd:integer")) || o.datatype.equals(this.context.resolve("xsd:double")) || o.datatype.equals(this.context.resolve("xsd:decimal")) || o.datatype.equals(this.context.resolve("xsd:boolean"))) {
            return o.value;
          } else {
            return '"' + o.value + '"^^' + this.shrink(o.type);
          }
        }
        return o.toNT();
      };
      Turtle.prototype.propertyObjectChain = function(po, indent) {
        var out, properties;
        if (indent == null) {
          indent = 2;
        }
        if (!po) {
          return;
        }
        out = "";
        properties = po.keys();
        properties.sort();
        if (this.contains(properties, "a")) {
          this.remove(properties, "a");
          properties.unshift("a");
        }
        _.forEach(properties, function(property, pi, pa) {
          out = out + (pi > 0 ? (new Array(indent + 1)).join(" ") : "") + property + " ";
          _.forEach(po.get(property), function(o, oi, oa) {
            var oindent;
            oindent = "";
            if (oa.length > 2) {
              oindent = "\n" + (new Array(indent + 2 + 1)).join(" ");
            }
            if (o.toString().charAt(0) === "_" && !this.nonAnonBNodes.exists(o.toString())) {
              if (this.lists.exists(o.toNT())) {
                out = out + this.renderList(o.toNT, indent + 3);
              } else {
                out = out + oindent + "[ " + this.anonBNode(o.toString(), indent + 2 + 2) + oindent + (oa.length === 1 ? " " : "") + "]";
              }
            } else {
              out = out + oindent + this.output(o);
            }
            if (oa.length - 1 !== oi) {
              if (oa.length > 2) {
                return out = out + "," + (new Array(indent + 2 + 2)).join(" ");
              } else {
                return out = out + ", ";
              }
            }
          }, this);
          return out = out + (pa.length - 1 === pi ? "" : ";\n");
        }, this);
        return out;
      };
      Turtle.prototype.render = function() {
        var invertedMap, out, prefixes;
        out = new Array;
        this.skipSubjects = this.nonAnonBNodes.keys();
        _.forEach(this.nonAnonBNodes.keys(), function(k, i, a) {
          if (this.nonAnonBNodes.get(k) === 1) {
            return this.nonAnonBNodes.remove(k);
          }
        }, this);
        _.forEach(this.index.keys(), function(subject, $is, $as) {
          var single;
          single = "";
          if (subject.charAt(0) === "_") {
            if (!this.nonAnonBNodes.exists(subject) && !this.contains(this.skipSubjects, subject)) {
              if (this.lists.exists(subject)) {
                single = this.renderList(subject, 2) + " " + this.propertyObjectChain(this.index.get(subject));
              } else {
                single = "[ " + this.anonBNode(subject, 2) + "\n]";
              }
            }
          } else {
            single = subject + " " + this.propertyObjectChain(this.index.get(subject));
          }
          if (single.length > 0) {
            return out.push(single + " .\n");
          }
        }, this);
        if (this.usedPrefixes.length > 0) {
          invertedMap = new api.Hash;
          _.forEach(this.prefixMap.keys(), function(k, i, h) {
            if (this.contains(this.usedPrefixes, k)) {
              return invertedMap.set(this.prefixMap.get(k), k);
            }
          }, this);
          prefixes = invertedMap.keys();
          prefixes.sort();
          prefixes.reverse();
          out.unshift("");
          _.forEach(prefixes, function(s, i, a) {
            return out.unshift("@prefix " + s + " <" + invertedMap.get(s) + "> .");
          }, this);
        }
        return out.join("\n");
      };
      Turtle.prototype.renderList = function(o, indent) {
        var li, lis, list, liststring, nl;
        list = new Array;
        _.forEach(this.lists.get(o), function(n, i, a) {
          return list.push(this.output(n));
        }, this);
        lis = new Array;
        liststring = "";
        while (list.length > 0) {
          li = list.shift();
          if (liststring.length + li.length < 75) {
            liststring = liststring.concat(li + " ");
          } else {
            lis.push(liststring);
            liststring = li + " ";
          }
        }
        lis.push(liststring);
        nl = lis.length === 1 ? " " : "\n" + (new Array(indent)).join(" ");
        return "(" + nl + lis.join(nl) + (lis.length === 1 ? "" : "\n") + ")";
      };
      Turtle.prototype.shrink = function(n, property) {
        var i, _g, _g1;
        if (property == null) {
          property = false;
        }
        if (property && n.equals(api.serializers.Turtle.RDF_TYPE)) {
          return "a";
        }
        if (n.equals(api.serializers.Turtle.RDF_NIL)) {
          return "()";
        }
        _g = 0;
        _g1 = this.prefixMap.keys();
        while (_g < _g1.length) {
          i = _g1[_g];
          ++_g;
          if (this.startsWith(n.toString(), i)) {
            if (!this.contains(this.usedPrefixes, i)) {
              this.usedPrefixes.push(i);
            }
            return n.toString().replace(i, this.prefixMap.get(i));
          }
        }
        return n.toNT();
      };
      Turtle.prototype.suckLists = function(graph) {
        var ends, members, pFilter, poFilter, sFilter, tFilter;
        sFilter = function(n) {
          return function(t, i, s) {
            return t.subject.equals(n);
          };
        };
        pFilter = function(n) {
          return function(t, i, s) {
            return t.property.equals(n);
          };
        };
        poFilter = function(p, o) {
          return function(t, i, s) {
            return t.property.equals(p) && t.object.equals(o);
          };
        };
        tFilter = function(a) {
          return function(t, i, s) {
            return !(t.subject.equals(a.subject) && t.property.equals(a.property) && t.object.equals(a.object));
          };
        };
        members = graph.filter(function(t, i, s) {
          return t.property.equals(api.serializers.Turtle.RDF_FIRST) || t.property.equals(api.serializers.Turtle.RDF_REST);
        });
        _.forEach(members, function(t, i, s) {
          return graph = graph.filter(tFilter(t));
        });
        ends = members.filter(function(t, i, s) {
          return t.object.equals(api.serializers.Turtle.RDF_NIL);
        });
        _.forEach(ends, function(n, i, s) {
          var q, start, tmplist;
          tmplist = new Array;
          q = n;
          start = null;
          while (q !== null) {
            start = q.subject;
            tmplist.unshift(members.filter(sFilter(start)).filter(pFilter(api.serializers.Turtle.RDF_FIRST)).toArray().pop().object);
            members = members.filter(function(t, i1, s1) {
              return !t.subject.equals(start);
            });
            q = members.filter(poFilter(api.serializers.Turtle.RDF_REST, start)).toArray().pop();
          }
          return this.lists.set(start.toNT(), tmplist);
        }, this);
        return graph;
      };
      return Turtle;
    })();
    api.serializers.Turtle.NS_RDF = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
    api.serializers.Turtle.RDF_TYPE = api.createNamedNode(api.serializers.Turtle.NS_RDF + "type");
    api.serializers.Turtle.RDF_RDF = api.createNamedNode(api.serializers.Turtle.NS_RDF + "RDF");
    api.serializers.Turtle.RDF_FIRST = api.createNamedNode(api.serializers.Turtle.NS_RDF + "first");
    api.serializers.Turtle.RDF_REST = api.createNamedNode(api.serializers.Turtle.NS_RDF + "rest");
    api.serializers.Turtle.RDF_NIL = api.createNamedNode(api.serializers.Turtle.NS_RDF + "nil");
    api.nt = function(graph) {
      return new api.serializers.NTriples(api).serialize(graph);
    };
    return api.turtle = function(graph) {
      return new api.serializers.Turtle(api).serialize(graph);
    };
  })(rdf);
  (function(api) {
    api.filters = {
      s: function(s) {
        if (_.isArray(s)) {
          return function(t) {
            var i, _i, _len;
            for (_i = 0, _len = s.length; _i < _len; _i++) {
              i = s[_i];
              if (t.s.equals(s)) {
                return true;
              }
            }
            return false;
          };
        }
        return function(t) {
          return t.s.equals(s);
        };
      },
      p: function(p) {
        if (_.isArray(p)) {
          return function(t) {
            var i, _i, _len;
            for (_i = 0, _len = p.length; _i < _len; _i++) {
              i = p[_i];
              if (t.p.equals(i)) {
                return true;
              }
            }
            return false;
          };
        }
        return function(t) {
          return t.p.equals(p);
        };
      },
      o: function(o) {
        if (_.isArray(o)) {
          return function(t) {
            var i, _i, _len;
            for (_i = 0, _len = o.length; _i < _len; _i++) {
              i = o[_i];
              if (t.o.equals(i)) {
                return true;
              }
            }
            return false;
          };
        }
        return function(t) {
          return t.o.equals(o);
        };
      },
      sp: function(s, p) {
        if (!_.isArray(s)) {
          s = [s];
        }
        if (!_.isArray(p)) {
          p = [p];
        }
        return function(t) {
          var prop, sub, _i, _j, _len, _len2;
          for (_i = 0, _len = s.length; _i < _len; _i++) {
            sub = s[_i];
            for (_j = 0, _len2 = p.length; _j < _len2; _j++) {
              prop = p[_j];
              if (t.p.equals(prop) && t.s.equals(sub)) {
                return true;
              }
            }
          }
          return false;
        };
      },
      so: function(s, o) {
        if (!_.isArray(s)) {
          s = [s];
        }
        if (!_.isArray(o)) {
          o = [o];
        }
        return function(t) {
          var obj, sub, _i, _j, _len, _len2;
          for (_i = 0, _len = s.length; _i < _len; _i++) {
            sub = s[_i];
            for (_j = 0, _len2 = o.length; _j < _len2; _j++) {
              obj = o[_j];
              if (t.s.equals(sub) && t.o.equals(obj)) {
                return true;
              }
            }
          }
          return false;
        };
      },
      po: function(p, o) {
        if (!_.isArray(p)) {
          p = [p];
        }
        if (!_.isArray(o)) {
          o = [o];
        }
        return function(t) {
          var obj, prop, _i, _j, _len, _len2;
          for (_i = 0, _len = p.length; _i < _len; _i++) {
            prop = p[_i];
            for (_j = 0, _len2 = o.length; _j < _len2; _j++) {
              obj = o[_j];
              if (t.p.equals(prop) && t.o.equals(obj)) {
                return true;
              }
            }
          }
          return false;
        };
      },
      spo: function(s, p, o) {
        if (!_.isArray(s)) {
          s = [s];
        }
        if (!_.isArray(p)) {
          p = [p];
        }
        if (!_.isArray(o)) {
          o = [o];
        }
        return function(t) {
          var obj, prop, sub, _i, _j, _k, _len, _len2, _len3;
          for (_i = 0, _len = s.length; _i < _len; _i++) {
            sub = s[_i];
            for (_j = 0, _len2 = p.length; _j < _len2; _j++) {
              prop = p[_j];
              for (_k = 0, _len3 = o.length; _k < _len3; _k++) {
                obj = o[_k];
                if (t.s.equals(sub) && t.p.equals(prop) && t.o.equals(obj)) {
                  return true;
                }
              }
            }
          }
          return false;
        };
      },
      describes: function(o) {
        if (_.isArray(o)) {
          return function(t) {
            var noun, _i, _len;
            for (_i = 0, _len = o.length; _i < _len; _i++) {
              noun = o[_i];
              if (t.s.equals(noun) || t.o.equals(noun)) {
                return true;
              }
            }
            return false;
          };
        }
        return function(t) {
          return t.s.equals(o) || t.o.equals(o);
        };
      },
      type: function(o) {
        var RDF_TYPE;
        RDF_TYPE = api.resolve("rdf:type");
        if (_.isArray(o)) {
          return function(t) {
            var i, _i, _len;
            for (_i = 0, _len = o.length; _i < _len; _i++) {
              i = o[_i];
              if (t.p.equals(RDF_TYPE) && t.o.equals(i)) {
                return true;
              }
            }
            return false;
          };
        }
        return function(t) {
          return t.p.equals(RDF_TYPE) && t.o.equals(o);
        };
      },
      constrainedTriple: function() {
        return function(t) {
          return (t.s.interfaceName === 'NamedNode' || t.s.interfaceName === 'BlankNode') && t.p.interfaceName === 'NamedNode';
        };
      },
      link: function() {
        return function(t) {
          return t.s.interfaceName === 'NamedNode' && t.p.interfaceName === 'NamedNode' && t.o.interfaceName === 'NamedNode';
        };
      }
    };
    api.filterCount = function(g, f) {
      var c;
      c = 0;
      _.forEach(g, function(t) {
        return f(t) && ++c;
      });
      return c;
    };
    api.isOldSchool = function(g) {
      return g.every(api.filters.constrainedTriple());
    };
    return api.links = function(g) {
      return g.filter(api.filters.link());
    };
  })(rdf);
  (function(api) {
    api.BaseGraph = api.Graph;
    return api.Graph = (function() {
      function Graph(a) {
        _.extend(this, new api.BaseGraph(a));
      }
      Graph.prototype._distinct = function(a) {
        var i, o, _i, _len, _ref;
        o = new api.Hash;
        _ref = this._graph;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          i = _ref[_i];
          if (!o.exists(i[a].h())) {
            o.set(i[a].h(), i[a]);
          }
        }
        console.log(o);
        return o.toArray();
      };
      Graph.prototype.subjects = function() {
        return this._distinct('s');
      };
      Graph.prototype.predicates = function() {
        return this._distinct('p');
      };
      Graph.prototype.objects = function() {
        return this._distinct('s');
      };
      Graph.prototype.isGround = function() {
        return this.every(function(t) {
          return !(t.s.interfaceName === "BlankNode" || t.p.interfaceName === "BlankNode" || t.o.interfaceName === "BlankNode");
        });
      };
      return Graph;
    })();
  })(rdf);
  (function(api) {
    api.Converter = (function() {
      function Converter() {}
      Converter.prototype.c = null;
      Converter.prototype._string = function(s, a) {
        if (!(Boolean(a).valueOf() || a.indexOf(":") < 0)) {
          return api.createLiteral(s, a);
        }
        return api.createLiteral(s, api.ref(a));
      };
      Converter.prototype._boolean = function(b) {
        return api.createLiteral((b ? "true" : "false"), api.ref('xsd:boolean'));
      };
      Converter.prototype._date = function(d, ms) {
        var pad, s;
        pad = function(n) {
          if (n < 10) {
            return '0' + n;
          } else {
            return n;
          }
        };
        s = d.getUTCFullYear() + "-" + pad(d.getUTCMonth() + 1) + '-' + pad(d.getUTCDate()) + 'T';
        s += pad(d.getUTCHours()) + ":" + pad(d.getUTCMinutes()) + ":" + pad(d.getUTCSeconds());
        if (ms) {
          s = (d.getUTCMilliseconds() > 0 ? s + '.' + d.getUTCMilliseconds() : s);
        }
        return api.createLiteral(s += 'Z', api.ref('xsd:dateTime'));
      };
      Converter.prototype._number = function(n) {
        if (n === Number.POSITIVE_INFINITY) {
          return api.createLiteral('INF', api.ref('xsd:double'));
        }
        if (n === Number.NEGATIVE_INFINITY) {
          return api.createLiteral('-INF', api.ref('xsd:double'));
        }
        if (n === Number.NaN) {
          return api.createLiteral('NaN', api.ref('xsd:double'));
        }
        n = n.toString();
        if (api.Converter.INTEGER.test(n)) {
          return api.createLiteral(n, api.ref('xsd:integer'));
        }
        if (api.Converter.DECIMAL.test(n)) {
          return api.createLiteral(n, api.ref('xsd:decimal'));
        }
        if (api.Converter.DOUBLE.test(n)) {
          return api.createLiteral(n, api.ref('xsd:double'));
        }
        throw new TypeError("Can't convert weird number: " + n);
      };
      Converter.prototype.convert = function(l, r) {
        switch (typeof l) {
          case 'string':
            return this._string(l, r);
          case 'boolean':
            return this._boolean(l);
          case 'number':
            return this._number(l);
          case 'object':
            switch (l.constructor.name) {
              case 'Boolean':
                return this._boolean(l.valueOf());
              case 'Date':
                return this._date(l, r);
              case 'Number':
                return this._number(l);
            }
        }
        throw new TypeError("Cannot convert type: " + l.constructor.name);
      };
      return Converter;
    })();
    api.Converter.INTEGER = new RegExp("^(-|\\+)?[0-9]+$", "");
    api.Converter.DOUBLE = new RegExp("^(-|\\+)?(([0-9]+\\.[0-9]*[eE]{1}(-|\\+)?[0-9]+)|(\\.[0-9]+[eE]{1}(-|\\+)?[0-9]+)|([0-9]+[eE]{1}(-|\\+)?[0-9]+))$", "");
    api.Converter.DECIMAL = new RegExp("^(-|\\+)?[0-9]*\\.[0-9]+?$", "");
    api.converter = new api.Converter;
    return api.literal = function(o, t) {
      return api.converter.convert(o, t);
    };
  })(rdf);
  (function(api) {
    api.log = function(o) {
      return console.log(o);
    };
    api.ref = function(v) {
      if (v != null) {
        return this.createNamedNode(this.iri(v));
      } else {
        return this.createBlankNode;
      }
    };
    api.iri = function(i) {
      var o;
      return this.createIRI((o = this.resolve(i) != null) ? o : i);
    };
    return api.node = function(v, t) {
      if (t != null) {
        return this.literal(v, t);
      }
      if (v == null) {
        return this.createBlankNode();
      }
      if (typeof v === "string" && v.indexOf(":") >= 0) {
        return this.ref(v);
      }
      return this.literal(v);
    };
  })(rdf);
  (function(api) {
    var prefixes;
    prefixes = {
      owl: "http://www.w3.org/2002/07/owl#",
      rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
      rdfs: "http://www.w3.org/2000/01/rdf-schema#",
      rdfa: "http://www.w3.org/ns/rdfa#",
      xhv: "http://www.w3.org/1999/xhtml/vocab#",
      xml: "http://www.w3.org/XML/1998/namespace",
      xsd: "http://www.w3.org/2001/XMLSchema#",
      grddl: "http://www.w3.org/2003/g/data-view#",
      powder: "http://www.w3.org/2007/05/powder#",
      powders: "http://www.w3.org/2007/05/powder-s#",
      rif: "http://www.w3.org/2007/rif#",
      atom: "http://www.w3.org/2005/Atom/",
      xhtml: "http://www.w3.org/1999/xhtml#",
      formats: "http://www.w3.org/ns/formats/",
      xforms: "http://www.w3.org/2002/xforms/",
      xhtmlvocab: "http://www.w3.org/1999/xhtml/vocab/",
      xpathfn: "http://www.w3.org/2005/xpath-functions#",
      http: "http://www.w3.org/2006/http#",
      link: "http://www.w3.org/2006/link#",
      time: "http://www.w3.org/2006/time#",
      acl: "http://www.w3.org/ns/auth/acl#",
      cert: "http://www.w3.org/ns/auth/cert#",
      rsa: "http://www.w3.org/ns/auth/rsa#",
      crypto: "http://www.w3.org/2000/10/swap/crypto#",
      list: "http://www.w3.org/2000/10/swap/list#",
      log: "http://www.w3.org/2000/10/swap/log#",
      math: "http://www.w3.org/2000/10/swap/math#",
      os: "http://www.w3.org/2000/10/swap/os#",
      string: "http://www.w3.org/2000/10/swap/string#",
      doc: "http://www.w3.org/2000/10/swap/pim/doc#",
      contact: "http://www.w3.org/2000/10/swap/pim/contact#",
      p3p: "http://www.w3.org/2002/01/p3prdfv1#",
      swrl: "http://www.w3.org/2003/11/swrl#",
      swrlb: "http://www.w3.org/2003/11/swrlb#",
      exif: "http://www.w3.org/2003/12/exif/ns#",
      earl: "http://www.w3.org/ns/earl#",
      ma: "http://www.w3.org/ns/ma-ont#",
      sawsdl: "http://www.w3.org/ns/sawsdl#",
      sd: "http://www.w3.org/ns/sparql-service-description#",
      skos: "http://www.w3.org/2004/02/skos/core#",
      fresnel: "http://www.w3.org/2004/09/fresnel#",
      gen: "http://www.w3.org/2006/gen/ont#",
      timezone: "http://www.w3.org/2006/timezone#",
      skosxl: "http://www.w3.org/2008/05/skos-xl#",
      org: "http://www.w3.org/ns/org#",
      ical: "http://www.w3.org/2002/12/cal/ical#",
      wgs84: "http://www.w3.org/2003/01/geo/wgs84_pos#",
      vcard: "http://www.w3.org/2006/vcard/ns#",
      turtle: "http://www.w3.org/2008/turtle#",
      pointers: "http://www.w3.org/2009/pointers#",
      dcat: "http://www.w3.org/ns/dcat#",
      imreg: "http://www.w3.org/2004/02/image-regions#",
      rdfg: "http://www.w3.org/2004/03/trix/rdfg-1/",
      swp: "http://www.w3.org/2004/03/trix/swp-2/",
      rei: "http://www.w3.org/2004/06/rei#",
      wairole: "http://www.w3.org/2005/01/wai-rdf/GUIRoleTaxonomy#",
      states: "http://www.w3.org/2005/07/aaa#",
      wn20schema: "http://www.w3.org/2006/03/wn/wn20/schema/",
      httph: "http://www.w3.org/2007/ont/httph#",
      act: "http://www.w3.org/2007/rif-builtin-action#",
      common: "http://www.w3.org/2007/uwa/context/common.owl#",
      dcn: "http://www.w3.org/2007/uwa/context/deliverycontext.owl#",
      hard: "http://www.w3.org/2007/uwa/context/hardware.owl#",
      java: "http://www.w3.org/2007/uwa/context/java.owl#",
      loc: "http://www.w3.org/2007/uwa/context/location.owl#",
      net: "http://www.w3.org/2007/uwa/context/network.owl#",
      push: "http://www.w3.org/2007/uwa/context/push.owl#",
      soft: "http://www.w3.org/2007/uwa/context/software.owl#",
      web: "http://www.w3.org/2007/uwa/context/web.owl#",
      content: "http://www.w3.org/2008/content#",
      vs: "http://www.w3.org/2003/06/sw-vocab-status/ns#",
      air: "http://dig.csail.mit.edu/TAMI/2007/amord/air#",
      ex: "http://example.org/",
      dc: "http://purl.org/dc/terms/",
      dc11: "http://purl.org/dc/elements/1.1/",
      dctype: "http://purl.org/dc/dcmitype/",
      foaf: "http://xmlns.com/foaf/0.1/",
      cc: "http://creativecommons.org/ns#",
      opensearch: "http://a9.com/-/spec/opensearch/1.1/",
      'void': "http://rdfs.org/ns/void#",
      sioc: "http://rdfs.org/sioc/ns#",
      sioca: "http://rdfs.org/sioc/actions#",
      sioct: "http://rdfs.org/sioc/types#",
      lgd: "http://linkedgeodata.org/vocabulary#",
      moat: "http://moat-project.org/ns#",
      days: "http://ontologi.es/days#",
      giving: "http://ontologi.es/giving#",
      lang: "http://ontologi.es/lang/core#",
      like: "http://ontologi.es/like#",
      status: "http://ontologi.es/status#",
      og: "http://opengraphprotocol.org/schema/",
      protege: "http://protege.stanford.edu/system#",
      dady: "http://purl.org/NET/dady#",
      uri: "http://purl.org/NET/uri#",
      audio: "http://purl.org/media/audio#",
      video: "http://purl.org/media/video#",
      gridworks: "http://purl.org/net/opmv/types/gridworks#",
      hcterms: "http://purl.org/uF/hCard/terms/",
      bio: "http://purl.org/vocab/bio/0.1/",
      cs: "http://purl.org/vocab/changeset/schema#",
      geographis: "http://telegraphis.net/ontology/geography/geography#",
      doap: "http://usefulinc.com/ns/doap#",
      daml: "http://www.daml.org/2001/03/daml+oil#",
      geonames: "http://www.geonames.org/ontology#",
      sesame: "http://www.openrdf.org/schema/sesame#",
      cv: "http://rdfs.org/resume-rdf/",
      wot: "http://xmlns.com/wot/0.1/",
      media: "http://purl.org/microformat/hmedia/",
      ctag: "http://commontag.org/ns#"
    };
    return api.prefixes.addAll(prefixes);
  })(rdf);
}).call(this);

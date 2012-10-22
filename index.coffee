$ = require "jquery"
_ = require "underscore"
edn = require "jsedn"

parseTag = (str, defaultTag) ->
	bindTo = {id: false, class: [], tag: false}

	if "#" in str
		[tag, rest] = str.split "#"
		
		if not tag.length
			tag = defaultTag
		
		[id, klass...] = rest.split "."
	else if "." in str
		id = false
		
		[tag, klass...] = str.split "."
		
		if not tag.length 
			tag = defaultTag
	else
		tag = str
		id = false
		klass = false

	if id[0] is "@"
		bindTo.id = true 
		id = id[1..-1]

	if tag[0] is "@"
		bindTo.tag = true
		tag = tag[1..-1]

	for k,i in klass 
		if k[0] is "@" 
			klass[i] = k[1..-1]
			bindTo.class.push klass[i]

	return tagName: tag, class: klass, id: id, bindTo: bindTo, options: {}
	
addToEnv = (env, key, val) ->
	if not env[key]?
		env[key] = $()
		
	env[key] = env[key].add val

prepTags = (taglist, defaultTag) ->
	prepped = []
	last = false
	for t in taglist
		if _.isArray t
			prepped.push last = prepTags t
		else if (not _.isArray t) and _.isObject t
			if not last
				throw "trying to apply options without a prior element"
			last.options = t
		else
			prepped.push last = parseTag t, defaultTag
			
	prepped
	
eden = (str, options = {}, onCreate) ->
	if _.isFunction options
		options = onCreate: options
	if _.isFunction onCreate
		options.onCreate = onCreate

	options.onCreate or= ->
	options.appendTo or= false
	options.defaultTag or= "div"
	options.self or= {}

	if str[0] isnt "[" then str = "[#{str}]"

	elAttrs = {}
	
	for k, v of options when k not in ["appendTo", "onCreate", "defaultTag", "self"]
		elAttrs[k] = v
		
	env = {}
	tags = []

	reifyOptions = (options, env, listeners, path = []) ->
		result = {}
		for key, value of options
			key = key.replace /\:/g, ""
			if _.isObject value
				reified = reifyOptions value, env, listeners, path.concat [key]
				if _.size reified 
					result[key] = reified
			else if value[0] is "@"
				val =  env
				for part in value[1..-1].split "."
					val = val[part]

				if val.broadcaster?
					listeners.push path: (path.concat [key]), fn: val
				else
					if _.isFunction val
						val = _.bind val, env
					result[key] = val	
			else
				result[key] = value
		result
		
	handleTags = (tagList, appendTo, isRoot = false) ->
		arrOptions = tagList.options or {}
		for tag in tagList
			if _.isArray tag
				handleTags tag, $tag
			else
				listenTo = []
				reified = reifyOptions _.extend(tag.options, elAttrs, arrOptions), options.self, listenTo
				console.log listenTo, reified
				tags.push $tag = $("<#{tag.tagName}/>", reified)
				
				if isRoot
					appendTo = appendTo.add $tag
				else
					appendTo.append $tag
			
				addToEnv env, tag.tagName, $tag
		
				if tag.class
					$tag.addClass tag.class.join " "
					addToEnv(env, klass, $tag) for klass in tag.class
		   
				if tag.id
					$tag.attr id: tag.id
					addToEnv env, tag.id, $tag
		
				if tag.bindTo.id
					options.self["$"+tag.id] = $tag
				for k in tag.bindTo.class
					options.self["$"+k] = $tag
				if tag.bindTo.tag
					options.self["$"+tag.tagName] = $tag

		appendTo
		
	appendTo = options.appendTo
	if _.isString appendTo then appendTo = $ appendTo
	rootTag = handleTags (prepTags edn.toJS(edn.parse str), options.defaultTag), (appendTo or $()), appendTo is false
	env._ = options.self
	options.onCreate?.apply env, tags
	rootTag

module.exports = eden

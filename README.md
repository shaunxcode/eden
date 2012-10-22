#eden


eden utilizes an edn esque syntax for creating dom fragments. 


##Syntax
	view =
		model:
			name: "walter"
			id: 1
			age: 33
			weight: 200
		talk: ->
			alert "#{@model.name} says hello"
			
	eden """
		ul.@person [
			li.@age {text @model.age} 
			li.@weight {text @model.weight}
		] {class: item}
		button {text "talk" click @talk}
	""", {self: view}
	
Yields:
```<ul class="person"><li class="age item">33</li><li class="weight item">200</li></ul><button>talk</button>```
	
	[
		"ul.@person", [
			"li.@age", text: "@model.age"
	]
Children are nested inside of a vector/array syntax and attributes are passed as a map. The keys in the map may be pre/post fixed with : - this is ignored. e.g. text, :text, text: and :text: are all equivelant. The main string itself may optionally be wrapped in a vector as well.

The second param ```{self: this}``` provides the context for the @ bindings. If you specify a handler on an event like click: it will be bound to the self context. 

The view now also has jquery handles of $person, $age, and $weight (anywhere the @ syntax is used directy after the start of an id or class declaration or at the start of a tag). 

##Argument Arities
```eden tagString, [{self, appendTo, onCreate, defaultTag, [any valid jquery options you could pass when creating a tag]}]```

```eden tagString, onCreate```

```eden tagString, {options}, onCreate```
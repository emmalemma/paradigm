#TODO: I have no memory of what I was going to write here.

$_call = (function_name, args...) ->
	request = new Request.JSON(
							{url:'/$/'+function_name[1..], 
							onSuccess:$_callback
							})	
	if args.length > 0
		kwargs = args.pop()
		
		if typeof kwargs.callback == "function"
			kwargs._callback = anon_func(kwargs.callback)
		else if typeof kwargs.callback == "string"
			kwargs._callback = kwargs.callback
		delete kwargs.callback
		
		if typeof kwargs.where == "object"
			kwargs._where = kwargs.where.id or anon_el(kwargs.where)
		else if typeof kwargs.where == "string"
			kwargs._where = kwargs.where
		delete kwargs.where
		
		if args.length > 0
			kwargs._fargs=args	
		return request.send(JSON.stringify(kwargs))
	else 
		return request.get()
	request

#TODO: garbage collect this (bleh)
anon_funcs =
	count: 0
	
anon_func = (f) ->
	for fname of anon_funcs
		if anon_funcs[fname] == f
			k = fname
			break
		
	if not k
		k = "_F#{(anon_funcs.count+=1).toString(36)}"
		anon_funcs[k] = window[k] = f
		
	return k

anon_els = 0
anon_el = (el) ->
	k = "_E#{(e+=1).toString(36)}"
	el.id = k
	return k

text =(data)-> $(data._where).set('text',data._data)
update =(data)-> console.log "Update:"+data
append =(data)-> console.log "Append:"+data
remove =(data)-> console.log "Remove:"+data

$_callback = (obj, text) ->
	console.log "Callback:"
	console.log obj
	if obj._callback
		window[obj._callback](obj)
	
routed_functions = {%ROUTED_FUNCS%}

for f in routed_functions
	window[f] = (args...) ->
		console.log args
		$_call("#{f}", args...)
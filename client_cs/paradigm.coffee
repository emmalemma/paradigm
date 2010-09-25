#TODO:
$_call = (function_name, args...) ->
	request = new Request.JSON(
							{url:'/$/'+function_name[1..], 
							onSuccess:$_callback
							})	
		
	if args.length > 1
		fargs = args
		args = args.pop()
		args._fargs=fargs
		return request.send(JSON.stringify(args))	
	if args.length == 1
		return request.send(JSON.stringify(args[0]))
	else 
		return request.get()
	request


text =(data)-> $(data._where).set('text',data._data)
update =(data)-> console.log "Update:"+data
append =(data)-> console.log "Append:"+data
remove =(data)-> console.log "Remove:"+data

$_callback = (obj, text) ->
	if obj._callback
		window[obj._callback](obj)
		
routed_functions = {%ROUTED_FUNCS%}

for f in routed_functions
	window[f] = (args...) ->
		args[args.length-1]._where = _where
		$_call("#{f}", args...)
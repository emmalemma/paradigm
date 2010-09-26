fs = require 'fs'

client = require './clientside'

routed_funcs = []

@route_function_call = (req, res) ->
	if req.url[0..2] != "/$/"
		return false
	
	fname = "$#{req.url[3..]}"
	
	@log "Routing call for #{fname}"
	
	if fname of routed_funcs
		rfunc = routed_funcs[fname]
	else	
		res.writeHead 500, {'Content-Type': 'application/json'}
		return res.end JSON.stringify({error: "No such call."})

	res.writeHead 200, {'Content-Type': 'application/json'}	   
	
	@_sessid	= req.getCookie("_sessid")
	@_ip 		= req.connection.remoteAddress
	
	finish =(data)=> 
		parsed_data = JSON.parse(data or '{}')
		@respond =(data)-> res.end JSON.stringify( {_data: data or null, _callback: parsed_data._callback or null, _where: parsed_data._where or null })
		rfunc = rfunc.bind this
		if parsed_data._fargs #compiler limitation?
			@respond rfunc(parsed_data._fargs..., parsed_data._data...)
		else
			@respond rfunc(parsed_data._data...)
		
	if req.method == "POST"
		req.on 'data', finish
		
	else if req.method == "GET"
		finish()
		
	return true

@route =(name, func)-> routed_funcs[name] = func

@route_shared_functions =()->
	server_code = require '../'+@Config.server_code
	console.log "Routing shared functions..."
	for i of server_code
		if i[0] == '$'
			routed_funcs[i] = server_code[i]
			
	client.copy_routes.bind(this) routed_funcs
	
	console.log "Done!"
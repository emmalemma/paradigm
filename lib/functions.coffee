fs = require 'fs'

client = require './clientside'
cookie = ext 'cookie-node'

global.routed_funcs = []

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
		
	finish =(data)=> 
		parsed_data = JSON.parse(data or '{}')
		console.log parsed_data
		@respond =(data)-> res.end JSON.stringify( {_data: data or null, _callback: parsed_data._callback or null, _where: parsed_data._where or null })
		rfunc = rfunc.bind this
		if parsed_data._fargs #refactor me!
			value = rfunc(parsed_data._fargs..., parsed_data)
		else
			value = rfunc(parsed_data)
			
		if value != undefined
			@respond value
	if req.method == "POST"
		req.on 'data', finish
		
	else if req.method == "GET"
		finish()
		
	return true

@route =(name, func)-> 
	routed_funcs[name] = func

@route_shared_functions =()->
	server_code = require @Config.server_code
	console.log "Routing shared functions..."
	for i of server_code
		if i[0] == '$'
			routed_funcs[i] = server_code[i]
			
	client.copy_routes.bind(this) routed_funcs
	
	console.log "Done!"
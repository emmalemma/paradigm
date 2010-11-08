fs = require 'fs'

cookie = require 'cookie'

routed_funcs = []

@handle_request =->
	if not m = @Request.url.match @Config.middlewares.functions.match
		return false
	
	fname = m[1]
	
	@log "Routing call for #{fname}"
	
	if fname of routed_funcs
		rfunc = routed_funcs[fname]
	else	
		@Response.writeHead 500, {'Content-Type': 'application/json'}
		return @Response.end JSON.stringify({error: "No such call."})

	@Response.writeHead 200, {'Content-Type': 'application/json'}	   
		
	finish =(data)=> 
		parsed_data = JSON.parse(data or '{}')
		
		console.log parsed_data
		
		@respond =(data)=> @Response.end JSON.stringify( data )
		rfunc = rfunc.bind this
		if parsed_data._fargs #refactor me!
			value = rfunc(parsed_data._fargs..., parsed_data)
		else
			value = rfunc(parsed_data)
			
		if value != undefined
			@respond value
	if @Request.method == "POST"
		@Request.on 'data', finish
		
	else if @Request.method == "GET"
		finish()
		
	return true


@initialize =()->
	@route =(name, func)->  routed_funcs[name] = func
	
	try
		server_code = require @Config.server_code
	catch ex
		ex.message = "In #{@Config.server_code}: "+ex.message
		throw ex
		
	console.log "Routing shared functions..."
	prefix_matcher = new RegExp "^\\#{@Config.middlewares.functions.prefix}"
	for i of server_code
		if i.match(prefix_matcher)
			routed_funcs[i] = server_code[i]
	
	@Middlewares.functions.ClientSide = @Middlewares.functions.ClientSide.toString().replace("$ROUTED_FUNCS$",  JSON.stringify(name for name of routed_funcs))
	
	console.log "Done!"
	
@ClientSide =->
		`var __slice = Array.prototype.slice`
		`var __hasProp = Object.prototype.hasOwnProperty`
		
		$_call = (function_name, args...) ->							
			switch typeof args[args.length-1]
				when 'object' then kwargs = args.pop()
				when 'function'	then kwargs = {callback: args.pop()}
				
			request = new Request.JSON(
									{url: '/$/'+function_name, 
									onSuccess: kwargs.callback if kwargs
									})
			delete kwargs.callback if kwargs
			
			if args.length
				kwargs ?= {}
				kwargs._fargs = args
			
			if kwargs
				return request.send(JSON.stringify(kwargs))
			else
				return request.get()


		routed_functions = $ROUTED_FUNCS$
		
		for f in routed_functions
			window[f] = (args...) ->
				$_call("#{f}", args...)
	

sys = require 'sys'
path = require 'path'
http = require 'http'
fs = require 'fs'
cp = require 'child_process'

coffee = require './lib/coffee-script'
paperboy = require './lib/paperboy'

#CONFIG
#Example:
Config = 
	port: 8007
	#these do not seem to be absolute here...
	private_dir: path.join path.dirname(__filename), 'example/private'
	public_dir: path.join path.dirname(__filename), 'example/public'
	client_cs_dir: path.join path.dirname(__filename), 'example/private/cs/'
	client_js_dir: path.join path.dirname(__filename), 'example/public/js/'
	server_code: "./example/secret"
	db:
		adapter: 'couchdb'
		host: 'localhost'
		port: 5984
		name: 'test_app' #unused ATM

#GLOBALS

server_code = require Config.server_code

routed_funcs = []


#FUNCTIONS

log = console.log
print = sys.print

#wish this worked
#route =(func)-> routed_funcs[func.name] = func
route =(name, func)-> routed_funcs[name] = func

route '$routed_functions', -> name for name of routed_funcs

route_shared_functions =->
	log "Routing shared functions..."
	for i of server_code
		if i[0] == '$'
			log "#{i}"
			routed_funcs[i] = server_code[i]
	fs.readFile 'client_cs/paradigm.coffee', 'utf8', (err, data) -> #this could also work better
		fout = data.replace("{%ROUTED_FUNCS%}", JSON.stringify(routed_funcs['$routed_functions']()))
		fs.writeFile 'client_cs/paradigm.tmp', fout, 'utf8', (err) ->
			cp.exec "coffee -c -o #{Config.client_js_dir} --no-wrap client_cs/paradigm.tmp && rm client_cs/paradigm.tmp"
	log "Done!"
	
compile_clientside_scripts =->
	print "Compiling client-side coffeescripts into js... "
	cp.exec "cd #{Config.client_cs_dir} && coffee -c -o #{Config.client_js_dir} --no-wrap ."
	log "Done!"
	
parse_templates =->
	print "Parsing templates... "
	parse_dir = (dir) ->
		fs.readdir path.join(Config.private_dir, dir), (err, files) ->
			for f in files
				code = ""
				fs.readFile path.join(Config.private_dir, dir, f), 'utf8', (err, data) ->
				
					fs.mkdir path.join(Config.public_dir, dir), 493
				
					if not data #this probably means it's a directory...
						return parse_dir path.join(dir, f)
						
					if not f.match /.*\.html/
						return
						
					#match target tags (new way)
					while m = data.match /{= *(.+) *=}/
						data = data.replace m[0], "<div id='#{m[1]}'></div>"
					
					#match target tags (old way)
					# i = 0
					# while data.match "{="
					# 	k = "#{(i+=1).toString(36)}"
					# 	data = data.replace "{=", "<div id='#{k}'></div>{%_where='#{k}'\n"
					# data = data.replace /=}/g, "%}"
					
					#TODO: DRY this (or rather redo the whole templating system)
					blocks = data.split("{%")
					code = ""
					for block in blocks
						[a,b] = block.split "%}"
						code += ("<script>#{unwrapped_cs(a)}</script>#{b}" if b) or a
						
					blocks = code.split("{$")
					code = ""
					for block in blocks
						[a,b] = block.split "$}"
						code += ("<script>#{domready_cs(a)}</script>#{b}" if b) or a
					fs.writeFile path.join(Config.public_dir, dir, f), code, 'utf8', (err)->log err if err
					
					
	parse_dir ''
	log "Done!"

#TODO: figure out how to make the compiler not do this
unwrapped_cs = (code) ->
	matcher = /\(function\(\) {\n((.|\n)+)\n}\)\.call\(this\)\;\n/
	out = matcher.exec(coffee.CoffeeScript.compile(code))
	out[1]
	
domready_cs =(code)->
	unwrapped_cs "window.addEvent 'domready', ->
		#{code}"
	
db_client = http.createClient(Config.db.port, Config.db.host)
route_db_access =(req, res)->
	if req.url[0..4] != "/$db/"
		return false
	
	sys.log "Passing through #{req.method} #{req.url} to db"
	
	db_req = db_client.request 	req.method,
								req.url.match(/\/\$db(.+)/)[1],
								req.headers						
	db_req.on 'response', (db_res) ->
										res.writeHead 	db_res.statusCode,
														db_res.headers
										db_res.on 'data', (data)->
																	res.end(data)
	if req.method != "GET"
		req.on 'data', (data)->
								db_req.end(data)
	else
		db_req.end()
															
	return true

route_function_call = (req, res) ->
	if req.url[0..2] != "/$/"
		return false
	
	fname = "$#{req.url[3..]}"
	
	sys.log "Routing call for #{fname}"
	
	if fname of routed_funcs
		rfunc = routed_funcs[fname]
	else	
		res.writeHead 500, {'Content-Type': 'application/json'}
		return res.end JSON.stringify({error: "No such call."})

	res.writeHead 200, {'Content-Type': 'application/json'}	   
	
	finish =(data)-> 
		parsed_data = JSON.parse(data or '{}')
		log parsed_data
		if parsed_data._fargs #compiler limitation?
			return_data = rfunc(parsed_data._fargs..., parsed_data._data...)
		else
			return_data = rfunc(parsed_data._data...)
		
		res.end JSON.stringify( {_data: return_data, _callback: parsed_data._callback or null, _where: parsed_data._where or null })
	
	if req.method == "POST"
		req.on 'data', finish
		
	else if req.method == "GET"
		finish()
		
	return true
  
deliver_paperboy = (req, res) -> 
	ip = req.connection.remoteAddress
	
	pb = paperboy.deliver(Config.public_dir, req, res)
	pb = pb.addHeader 'Expires', 300
	pb = pb.addHeader 'X-PaperRoute', 'Node'
	pb = pb.before () -> sys.log "Serving static file for #{req.url}..."
	pb = pb.after (statCode) -> sys.log statCode
	pb = pb.error (statCode,msg) ->
			res.writeHead(statCode, {'Content-Type': 'text/plain'})
			res.end()
			sys.log statCode
	pb = pb.otherwise (err) ->
			statCode = 404;
			res.writeHead(statCode, {'Content-Type': 'text/plain'})
			res.end()
			sys.log statCode
			

issue = (file) ->
	cp.exec("cp #{file} #{path.join Config.client_js_dir, path.basename(file)}")

server = http.createServer (req, res) ->
	if not (route_function_call(req, res) or route_db_access(req, res))
		deliver_paperboy req, res

route_shared_functions()
compile_clientside_scripts()
parse_templates()

issue 'lib/mootools.js'

print "Starting listener on port #{Config.port}... "
server.listen Config.port
log "Listening."
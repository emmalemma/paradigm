sys = require 'sys'
path = require 'path'
fs = require 'fs'

paperboy = require 'paperboy'

@initialize =->
	for type of @Config.middlewares.paperboy.mimetypes
		console.log "adding type #{type}"
		paperboy.contentTypes[type] = @Config.middlewares.paperboy.mimetypes[type]

@handle_request =->
	ip = @Request.ip
	
	pb = paperboy.deliver(@Config.public_dir, @Request, @Response)
	pb = pb.addHeader 'Expires', 300
	pb = pb.addHeader 'X-PaperRoute', 'Node'
	#pb = pb.before () => #@log "Serving static file for #{@Request.url}..."
	pb = pb.after (statCode) => @log "PB-Served #{@Request.url}: #{statCode}"
	pb = pb.error (statCode,msg) =>
			@Response.writeHead(statCode, {'Content-Type': 'text/plain'})
			@Response.end("An error occurred.")
			@log "PB-Error serving #{@Request.url}: #{statCode}"
	pb = pb.otherwise (err) =>
			statCode = 404;
			@Response.writeHead(statCode, {'Content-Type': 'text/plain'})
			@Response.end("File not found.")
			@log "PB-#{@Request.url}: #{statCode}"
	true
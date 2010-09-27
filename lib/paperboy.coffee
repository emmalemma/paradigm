sys = require 'sys'
path = require 'path'
fs = require 'fs'

paperboy = ext 'paperboy'

this.deliver = (req, res) -> 
	ip = req.connection.remoteAddress
	
	pb = paperboy.deliver(@Config.public_dir, req, res)
	pb = pb.addHeader 'Expires', 300
	pb = pb.addHeader 'X-PaperRoute', 'Node'
	pb = pb.before () -> sys.log "Serving static file for #{req.url}..."
	pb = pb.after (statCode) -> sys.log statCode
	pb = pb.error (statCode,msg) ->
			res.writeHead(statCode, {'Content-Type': 'text/plain'})
			res.end("An error occurred.")
			sys.log statCode
	pb = pb.otherwise (err) ->
			statCode = 404;
			res.writeHead(statCode, {'Content-Type': 'text/plain'})
			res.end("File not found.")
			sys.log statCode

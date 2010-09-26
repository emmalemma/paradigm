http = require 'http'

@initialize =()->
	@db = require "../adapters/#{@Config.db.adapter}"
	@db.initialize(@Config)

class Model	
	constructor: (@id) -> 
		@db = this.client.db(@collection)

	set: (fields, callback) ->
		@db.saveDoc(@id, fields, callback)

	get:(callback)->
		@db.getDoc(@id, fields, callback)

@build_views =()->
	designs = require '../'+@Config.db.views
	for name of designs
		design = designs[name]
		db = @db.client.db(name.toLowerCase())
		db.getDoc	design._id, (err, doc)=>
								if not err
									design._rev = doc._rev
								db.saveDoc design._id, @db.toJSON(design), (err, doc) =>
																					if err
																						@log "Error saving design:"
																						@log err
		design_name = design._id.match(/_design\/(.+)/)[1]
		this[name] = {}
		for view of design.views
			this[name][view] =(query, cb)=> db.view(design_name, view, query, cb)
		console.log @Users.by_sessid
																			

db_client = null
@route_db_access =(req, res)->
	if req.url[0..4] != "/$db/"
		return false
	
	if not db_client
		db_client = http.createClient(@Config.db.port, @Config.db.host)
	
	@log "Passing through #{req.method} #{req.url} to db"
	
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
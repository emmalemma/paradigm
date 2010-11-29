@initialize =()->
	http = require 'http'
	couchdb = require 'couchdb'
	@db =
		toQuery: couchdb.toQuery
		toJSON: couchdb.toJSON
		client: couchdb.createClient(@Config.db.port, @Config.db.host)
		
	build_views.bind(this)()

build_views =()-> #todo this is fabulously ugly
	designs = require @Config.db.views
	@Models = {}
	for name of designs
		design = designs[name]
		db = @db.client.db(name.toLowerCase())
		
		if design.validate_doc_update?
			design_val_json = design.validate_doc_update.toString()
			validations_json = validations.toString().replace('$validate$', design_val_json)
			design.validate_doc_update = validations_json
		
		db.getDoc	design._id, (err, doc)=>
								if not err
									design._rev = doc._rev
								db.saveDoc design._id, @db.toJSON(design), (err, doc) =>
																					if err
																						@log "Error saving design:"
																						console.log err
		design_name = design._id.match(/_design\/(.+)/)[1]
		@Models[name] = db
		for view of design.views
			@Models[name][view] =(query, cb)=> db.view(design_name, view, query, cb)

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

validations =(newDoc, oldDoc, userCtx)->
		#this is the code to enable pretty validations
		permitted_fields = ['_id', '_revisions', '_rev']
		permit =(field)-> permitted_fields.push(field) if field of newDoc
		require =(field, message)-> unless permit(field) and newDoc[field] != ''
										throw(forbidden: message or "Document must have a #{field} field.")
										
		`var __hasProp = Object.prototype.hasOwnProperty;`
		disallow_others =(message)-> 
							for field of newDoc
								unless field in permitted_fields
									throw (forbidden: message or "Attribute '#{field}' is not permitted.") 
		integer =(field, message)-> 
									if (field of newDoc) and isNaN(parseInt(newDoc[field]))
										throw (forbidden: message or "'#{field}' must be an integer.") 
									else field
		number =(field, message)-> 	
									if (field of newDoc) and (typeof(newDoc[field]) != "number" or isNaN(newDoc[field]))
										throw (forbidden: message or "'#{field}' must be a number.") 
									else field
		email =(field, message)-> 
									if (field of newDoc) and not newDoc[field].match(/\b[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i)
										throw (forbidden: message or "'#{field}' must be a valid email address.") 
									else field
		validate_type =(field, type)-> true unless newDoc[field] and typeof(newDoc[field]) != type
		string =(field, message)-> 
									if not validate_type field, 'string'
										throw (forbidden: message or "'#{field}' must be a string.") 
									else field
		id_is =(func, field, message)-> func '_id', message
		
		submessage = subkey = ""
		 
		_like =(obj, vald, lax)->
			submessage = ""
			switch typeof(vald)
				when 'function' then 	return vald(obj)
				when 'string'
					submessage = "must be a #{vald} (is #{typeof obj})"
					return typeof obj == vald
				when 'object'
					return false unless typeof obj == 'object'
					if vald instanceof Array
						for val in obj
							unless _like val, vald[0]
								return false
						return true
					for key of obj
						subkey = key
						unless lax or (key of vald)
							return false
						unless _like obj[key], vald[key]	
							return false
					return true
				
		
		like =(name, field, obj)-> #todo this does not check backwards
			return unless newDoc[field]
			subkey = submessage = ''
			unless _like(newDoc[field], obj)
				throw forbidden: "#{field} must be a #{name}. (#{subkey} #{submessage})"
			field
		
		($validate$)(newDoc, oldDoc, userCtx)
		

couchdb = require '../ext/couchdb'
client = null

this.toQuery = couchdb.toQuery
this.toJSON = couchdb.toJSON
this.initialize=(config)->
	this.client = couchdb.createClient(config.db.port, config.db.host)
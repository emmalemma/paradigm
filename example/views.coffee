_db = require '../adapters/couchdb'

this.Users =
	_id: "_design/users"
	views:
		by_sessid:
			map: (doc)-> emit(doc.sessid, null)
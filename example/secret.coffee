_db = require '../adapters/couchdb'

@$datatoprint = (query) ->
	"Server speaking: no info about query '#{query}'"
	
@$get_current_user =->
	console.log @Users.by_sessid({key:@_sessid}, @respond)
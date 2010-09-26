sys = require 'sys'
path = require 'path'
http = require 'http'
fs = require 'fs'

cookie = require './ext/cookie-node'

#@Config
#Example:
@Config = 
	port: 8007
	#these do not seem to be absolute here...
	app_dir:		dir = path.join '.',path.dirname(__filename), 'example'
	private_dir: 	path.join dir, 'private'
	public_dir: 	path.join dir, 'public'
	client_cs_dir: 	path.join dir, 'private/cs/'
	client_js_dir: 	path.join dir, 'public/js/'
	server_code: 	"./example/secret"
	db:
		adapter: 'couchdb'
		host: 'localhost'
		port: 5984
		name: ''
		views: "./example/views"

#GLOBALS



#FUNCTIONS

@log = sys.log
@print = sys.print

templates = require './lib/templates'

functions = require './lib/functions'
route = functions.route.bind(this)
	
paperboy = require './lib/paperboy'

client = require './lib/clientside'
issue = client.issue.bind(this)

database = require './lib/database'

client = require './lib/clientside'

route '$routed_functions', -> name for name of routed_funcs
route '$get_sessid' , -> @_sessid or Math.random().toString(36)


server = http.createServer (req, res) =>
	if not (functions.route_function_call.bind(this)(req, res) or database.route_db_access.bind(this)(req, res))
		paperboy.deliver.bind(this) req, res




functions.route_shared_functions.bind(this)()

client.compile_clientside_scripts.bind(this)()

templates.parse_templates.bind(this)()

database.initialize.bind(this)()
database.build_views.bind(this)()


issue 'ext/mootools.js'

print "Starting listener on port #{@Config.port}... "
server.listen @Config.port
log "Listening."
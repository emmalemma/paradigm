sys = require 'sys'
path = require 'path'
http = require 'http'
fs = require 'fs'

@Run=(config)->

	@Config = config

	#FUNCTIONS

	@log = sys.log
	@print = sys.print

	templates = require './lib/templates'

	functions = require './lib/functions'
	route = functions.route.bind(this)
	
	paperboy = require './lib/paperboy'

	client = require './lib/clientside'
	issue = client.issue.bind(this)

	database = require "./lib/adapters/#{@Config.db.adapter}"

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


	issue path.join $EXTDIR, 'mootools.js'
	issue path.join $EXTDIR, 'mootools-more.js'

	print "Starting listener on port #{@Config.port}... "
	server.listen @Config.port
	log "Listening."
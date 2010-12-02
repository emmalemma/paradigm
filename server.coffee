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

	client = require './lib/clientside'
	issue = client.issue.bind(this)

	database = require "./lib/adapters/#{@Config.db.adapter}"

	client = require './lib/clientside'
	
	middleware = require './lib/middleware'

	server = http.createServer (req, res) =>
		RequestContext = 
						Middlewares: 	@Middlewares
						Config:			@Config
						Models:			@Models
						
						log:			sys.log
						
						Request: 	req
						Response: 	res
						
		middleware.before_request.bind(RequestContext)()
		middleware.handle_request.bind(RequestContext)()
		middleware.after_request.bind(RequestContext)()

	client.compile_clientside_scripts.bind(this)()

	templates.parse_templates.bind(this)()

	database.initialize.bind(this)()

	middleware.load_middlewares.bind(this)()

	# 
	# issue path.join $EXTDIR, 'mootools.js'
	# issue path.join $EXTDIR, 'mootools-more.js'

	print "Starting listener on port #{@Config.port}... "
	server.listen @Config.port
	log "Listening."
@Config = 
	paradigm_version: "0.2.0"
	
	port: 8007
	app_dir:		dir= '/path/to/example'
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
	
	watcher:
		ignore:   [	'.git'
					'example/public'
					'watcher.coffee' #kinda pointless, since it won't restart itself
					/^\..+/
					/\.tmp$/
					]

		verbose = no
		process = "paradigm"
		args = ["coffig.coffee"]
		timeout = 300 #seems like a good balance between cpu and responsiveness
		
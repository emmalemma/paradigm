fs = require 'fs'
path = require 'path'

unwrap =(str)-> (m[1] if m = /^function \(\) {((\n|.)+)}$/.exec str) or str
wrap =(str)-> "(#{str}).call(this);"
	

@load_middlewares =()->
	@Middlewares = {}
	if @Config.middlewares?
		for ware of @Config.middlewares
			try
				@Middlewares[ware] = require "./middlewares/#{ware}"
			catch ex
				ex.message =  "In middlewares/#{ware}: "+ex.message
				throw ex
				
			@Middlewares[ware].initialize.bind(this)()
			
			if @Middlewares[ware].ClientSide and @Config.middlewares[ware].client != no
				code = wrap(@Middlewares[ware].ClientSide.toString())
				fs.writeFile path.join(@Config.client_js_dir, "middlewares/#{ware}.js"), code, "utf8", (err)->console.log "Error writing middlewares/#{ware}.js: #{err}" if err
					
@before_every_request =->
						for name of @Middlewares
							if @Middlewares[name].before_every_request?
								@Middlewares[name].before_every_request.bind(this)()
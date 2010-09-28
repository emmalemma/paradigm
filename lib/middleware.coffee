fs = require 'fs'
path = require 'path'

unwrap =(str)-> (m[1] if m = /^function \(\) {((\n|.)+)}$/.exec str) or str
	

@load_middlewares =()->
	@Middlewares = {}
	if @Config.middlewares?
		for ware in @Config.middlewares
			@Middlewares[ware] = require "./middlewares/#{ware}"
			@Middlewares[ware].initialize.bind(this)()
			
			if @Middlewares[ware].ClientSide
				code = unwrap(@Middlewares[ware].ClientSide.toString())
				fs.writeFile path.join(@Config.client_js_dir, "middlewares/#{ware}.js"), code, "utf8", (err)->console.log "Error writing middlewares/#{ware}.js: #{err}" if err
					
@before_every_request =->
									for name of @Middlewares
										if @Middlewares[name].before_every_request?
											@Middlewares[name].before_every_request.bind(this)()
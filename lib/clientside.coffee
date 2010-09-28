cp = require 'child_process'
path = require 'path'
fs = require 'fs'

coffee = ext 'coffee-script'

@compile_clientside_scripts =()->
	console.log "Compiling client-side coffeescripts into js... "
	cp.exec "cd #{@Config.client_cs_dir} && coffee -c -o #{@Config.client_js_dir} --no-wrap ."
	console.log "Done!"

@copy_routes =(routes)->
	fs.readFile path.join($PARADIR, '/client_cs/paradigm.coffee'), 'utf8', (err, data) => #this could also work better
		console.log err if err
		
		code = data.replace("{%ROUTED_FUNCS%}", JSON.stringify(name for name of routes))
		
		code = code.replace("{%MIDDLEWARES%}", JSON.stringify(name for name of @Middlewares))
		
		fout = coffee.CoffeeScript.compile(code)
		fs.writeFile "#{@Config.client_js_dir}/paradigm.js", fout, 'utf8', (err) =>
			log err if err
	
@issue = (file) ->	
	cp.exec("cp #{file} #{path.join @Config.client_js_dir, path.basename(file)}")
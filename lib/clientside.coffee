cp = require 'child_process'
path = require 'path'
fs = require 'fs'

coffee = ext 'coffee-script'

@compile_clientside_scripts =()->
	console.log "Compiling client-side coffeescripts into js... "
	cp.exec "cd #{@Config.client_cs_dir} && coffee -c -o #{@Config.client_js_dir} --no-wrap ."
	console.log "Done!"
			
	
@issue = (file) ->	
	cp.exec("cp #{file} #{path.join @Config.client_js_dir, path.basename(file)}")
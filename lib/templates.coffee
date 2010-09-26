fs = require 'fs'
path = require 'path'
coffee = require '../ext/coffee-script'

#TODO: figure out how to make the compiler not do this
unwrapped_cs = (code) ->
	matcher = /\(function\(\) {\n((.|\n)*)\n}\)\.call\(this\)\;\n/
	out = matcher.exec(coffee.CoffeeScript.compile(code))
	out[1]
	
domready_cs =(code)->
	unwrapped_cs "window.addEvent 'domready', ->
		#{code}"

@parse_templates =()->
	@print "Parsing templates... "
	parse_dir = (dir) =>
		fs.readdir path.join(@Config.private_dir, dir), (err, files) =>
			for f in files
				code = ""
				fs.readFile path.join(@Config.private_dir, dir, f), 'utf8', (err, data) =>
				
					fs.mkdir path.join(@Config.public_dir, dir), 493
				
					if not data #this probably means it's a directory...
						return parse_dir path.join(dir, f)
						
					if not f.match /.*\.html/
						return
						
					#match target tags (new way)
					while m = data.match /{= *(.+) *=}/
						data = data.replace m[0], "<div id='#{m[1]}'></div>"
					
					#match target tags (old way)
					# i = 0
					# while data.match "{="
					# 	k = "#{(i+=1).toString(36)}"
					# 	data = data.replace "{=", "<div id='#{k}'></div>{%_where='#{k}'\n"
					# data = data.replace /=}/g, "%}"
					
					#TODO: DRY this (or rather redo the whole templating system)
					blocks = data.split("{%")
					code = ""
					for block in blocks
						[a,b] = block.split "%}"
						code += ("<script>#{unwrapped_cs(a)}</script>#{b}" if b) or a
						
					blocks = code.split("{$")
					code = ""
					for block in blocks
						[a,b] = block.split "$}"
						code += ("<script>#{domready_cs(a)}</script>#{b}" if b) or a
					fs.writeFile path.join(@Config.public_dir, dir, f), code, 'utf8', (err)->log err if err
					
					
	parse_dir ''
	@log "Done!"
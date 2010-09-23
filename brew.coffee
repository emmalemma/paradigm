fs = require 'fs'

server_output = "server-routes.coffee"
client_output = "client-routes.js"

open_files = 0

shared_functions = []

main = () ->
    filelist = process.argv
    
    open_files = filelist.length
    
    for i in filelist
        fs.readFile(i, 'utf8', handle_file)
    

handle_file = (err, data) ->
    catalogue_shared_functions data
    open_files -= 1
    handled_file()
  
catalogue_shared_functions = (data) ->
    lines = data.split('\n')
    for l in lines
        fname = /^\$([A-Za-z0-9_-]+).*/.exec(l)
        if fname
            shared_functions.push fname[1]
            
handled_file = () ->
    console.log "Handled file, #{open_files} left"
    if open_files == 0
        console.log "Cataloguing complete."
        console.log "Shared functions:"
        console.log shared_functions
        console.log "Generating client-side code:"
        console.log csc = client_side_code()
        console.log "Generating server-side code:"
        console.log ssc = server_side_code()
        fs.writeFile(server_output, ssc, "utf8")
        fs.writeFile(client_output, csc, "utf8")
        

client_side_code = () ->
    code = "$call = (function_name, args) -> jQuery.post('/$/#function_name', args, $callback, 'json')\n"
    code += "$callback = (data, status, request) -> console.log data \n"
    for f in shared_functions
        code += "$#{f} = (args...) -> $call('#{f}', args)\n"
    code
        
server_side_code = () ->
    code = "this is the hard part\n"
    for f in shared_functions
        code += "route '#{f}', $#{f}\n"
    code

main()
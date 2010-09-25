sys = require 'sys'
path = require 'path'
http = require 'http'
fs = require 'fs'
cp = require 'child_process'

coffee = require './lib/coffee-script'
paperboy = require './lib/paperboy'

#CONFIG
#Example:
PORT = 8007
#these do not seem to be absolute here...
PRIVATE_DIR = path.join path.dirname(__filename), 'example/private'
PUBLIC_DIR = path.join path.dirname(__filename), 'example/public'
CLIENT_CS_DIR = path.join path.dirname(__filename), 'example/private/cs/'
CLIENT_JS_DIR = path.join path.dirname(__filename), 'example/public/js/'
SERVER_CODE = "./example/secret"

#GLOBALS

server_code = require SERVER_CODE

routed_funcs = []


#FUNCTIONS

log = console.log
print = sys.print

#wish this worked
#route =(func)-> routed_funcs[func.name] = func
route =(name, func)-> routed_funcs[name] = func

route '$routed_functions', -> name for name of routed_funcs

route_shared_functions =->
    log "Routing shared functions..."
    for i of server_code
        if i[0] == '$'
            log "#{i}"
            routed_funcs[i] = server_code[i]
    fs.readFile 'client_cs/paradigm.coffee', 'utf8', (err, data) -> #this could also work better
        fout = data.replace("{%ROUTED_FUNCS%}", JSON.stringify(routed_funcs['$routed_functions']()))
        fs.writeFile 'client_cs/paradigm.tmp', fout, 'utf8', (err) ->
            cp.exec "coffee -c -o #{CLIENT_JS_DIR} --no-wrap client_cs/paradigm.tmp && rm client_cs/paradigm.tmp"
    log "Done!"
    
compile_clientside_scripts =->
    print "Compiling client-side coffeescripts into js... "
    cp.exec "cd #{CLIENT_CS_DIR} && coffee -c -o #{CLIENT_JS_DIR} --no-wrap ."
    log "Done!"
    
parse_templates =->
    print "Parsing templates... "
    parse_dir = (dir) ->
        fs.readdir path.join(PRIVATE_DIR, dir), (err, files) ->
            for f in files
                code = ""
                fs.readFile path.join(PRIVATE_DIR, dir, f), 'utf8', (err, data) ->
                
                    fs.mkdir path.join(PUBLIC_DIR, dir), 493
                
                    if not data #this probably means it's a directory...
                        return parse_dir path.join(dir, f)
                        
                    if not f.match /.*\.html/
                        return
                        
                    while data.match "{="
                        data = data.replace "{=", "{%_where=#{((i+=1 if i) or i = 0).toString(16)}\n"
                    data = data.replace /=}/g, "%}"
                    
                    blocks = data.split("{%")
                    code = ""
                    for block in blocks
                        [a,b] = block.split "%}"
                        code += ("<script>#{unwrapped_cs(a)}</script>#{b}" if b) or a
                    fs.writeFile path.join(PUBLIC_DIR, dir, f), code, 'utf8', (err)->log err if err
                    
                    
    parse_dir ''
    log "Done!"

unwrapped_cs = (code) ->
    matcher = /\(function\(\) {\n((.|\n)+)\n}\)\.call\(this\)\;\n/
    out = matcher.exec(coffee.CoffeeScript.compile(code))
    out[1]
    
server = http.createServer (req, res) ->
    ip = req.connection.remoteAddress
    if not route_function_call(req, res)
        deliver_paperboy req, res, ip

route_function_call = (req, res) ->
    if req.url[0..2] != "/$/"
        return false
    
    fname = "$#{req.url[3..]}"
    
    log "Received call for #{fname}..."
    
    if fname of routed_funcs
        rfunc = routed_funcs[fname]
    else    
        res.writeHead 500, {'Content-Type': 'application/json'}
        return res.end JSON.stringify({error: "No such call."})

    res.writeHead 200, {'Content-Type': 'application/json'}    
    
    finish =(data)-> res.end JSON.stringify( rfunc(data) )
    
    if req.method == "POST"
        req.on 'data', finish
        
    else if req.method == "GET"
        finish()
        
    return true

deliver_paperboy = (req, res, ip) -> 
    pb = paperboy.deliver(PUBLIC_DIR, req, res)
    pb = pb.addHeader 'Expires', 300
    pb = pb.addHeader 'X-PaperRoute', 'Node'
    pb = pb.before () -> sys.log 'Received Request'
    pb = pb.after (statCode) -> log statCode, req.url, ip
    pb = pb.error (statCode,msg) ->
            res.writeHead(statCode, {'Content-Type': 'text/plain'})
            res.end()
            log(statCode, req.url, ip, msg)
    pb = pb.otherwise (err) ->
            statCode = 404;
            res.writeHead(statCode, {'Content-Type': 'text/plain'})
            res.end()
            log(statCode, req.url, ip, err)
            
            
route_shared_functions()
compile_clientside_scripts()
parse_templates()
print "Starting listener on port #{PORT}... "
server.listen PORT
log "Listening."
sys = require 'sys'
path = require 'path'
http = require 'http'
fs = require 'fs'
cp = require 'child_process'

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
    fs.readFile 'shared_cs/client-routes.coffee', 'utf8', (err, data) -> #this could also work better
        fout = data.replace("{%%}", JSON.stringify(routed_funcs['$routed_functions']()))
        fs.writeFile 'shared_cs/client-routes.tmp', fout, 'utf8', (err) ->
            cp.exec "coffee -c -o #{CLIENT_JS_DIR} --no-wrap shared_cs/client-routes.tmp"
    log "Done!"
    
compile_clientside_scripts =->
    print "Compiling client-side coffeescripts into js... "
    cp.exec "cd #{CLIENT_CS_DIR} && coffee -c -o #{CLIENT_JS_DIR} --no-wrap ."
    log "Done!"
    
#TODO: make this recursive
parse_templates =-> #please, god, refactor this
    print "Parsing templates... "
    fs.readdir PRIVATE_DIR, (err, files) ->
        for f in files
            code = ""
            fs.readFile path.join(PRIVATE_DIR, f), 'utf8', (err, data) ->
                if not data 
                    return
                blocks = data.split("{%")
                slots = []
                it = 0
                
                done =->
                    if undefined in slots
                        return
                    fout = slots.join('')
                    fs.writeFile path.join(PUBLIC_DIR, f), fout, 'utf8'
                    
                for block in blocks
                    [a,b] = block.split "%}"
                    if b
                        coffee = cp.spawn("coffee", ["-sp"])
                        
                        ij = it #have to break the reference... there must be a better way to do this
                        coffee.stdout.on 'data', (data)->
                            slots[ij] = "<script>"+data+"</script>"
                            done()
                        
                        coffee.stdin.write a
                        coffee.stdin.end()
                        slots[it+1] = b
                        it += 2
                    else
                        slots[it] = a
                        it += 1
    log "Done!"
    
server = http.createServer (req, res) ->
    ip = req.connection.remoteAddress
    if not route_function_call(req, res)
        deliver_paperboy req, res, ip

route_function_call = (req, res) ->
    if req.url[0..2] != "/$/"
        return false
    
    fname = "$#{req.url[3..]}"
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
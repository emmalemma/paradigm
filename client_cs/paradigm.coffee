$_call = (function_name, args) ->
    request = new Request.JSON(
                            {url:'/$/'+function_name[1..], 
                            onSuccess:$_callback
                            })
    console.log args
    if args.length
        request.send(JSON.stringify(args))
    else
        request.get()
    request

$_callback = (obj, text) ->
    if obj.callback
        window[obj.callback](obj)

$puthere = (f, args...) ->
    console.log document.currentScript
    f(args...)

insert =(data)-> console.log "Insert:"+data
update =(data)-> console.log "Update:"+data
append =(data)-> console.log "Append:"+data
remove =(data)-> console.log "Remove:"+data

routed_functions = {%ROUTED_FUNCS%}

for f in routed_functions
    window[f] = (args...) ->
        args.where = _where
        $_call("#{f}", args)
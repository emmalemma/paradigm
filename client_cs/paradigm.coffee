$call = (function_name, args) -> jQuery.getJSON('/$/'+function_name[1..], JSON.stringify(args) if args.length, $callback)

$callback = (data, status, request) ->
    if data.callback
        console.log data.callback
        window[data.callback](data)

insert =(data)-> console.log data

routed_functions = {%ROUTED_FUNCS%}

for f in routed_functions
    window[f] = (args...) -> $call("#{f}", args)
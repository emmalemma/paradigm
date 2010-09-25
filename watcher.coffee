#TODO: does this actually catch every modification case?

sys = require 'sys'
fs = require 'fs'
path = require 'path'
cp = require 'child_process'

log =(args...)->(console.log args...) if VERBOSE

watched_files = []

POLL_TIMEOUT = 0
poll = (f) ->
	(args...) ->
		setTimeout f, POLL_TIMEOUT, args...
		
watch_dir =(dir)->
	handle_files = poll (err, files) ->
		for f in files
			fpath = path.join(dir, f)
			if fpath not in watched_files
				watch_file fpath, dir
				
		fs.readdir dir, handle_files
	
	fs.readdir dir, handle_files
			

watch_file =(file)->
	watched_files.push file
	last_modified = "new"
	for ig in IGNORE
		if file.match ig
			return log "Ignoring #{file}"
			
	log "Watching #{file}"
	handle_stats = poll (err, stats) ->
		if err
			return sys.log "Watcher error: #{err}"
		if stats.isDirectory()
			return watch_dir file
		
		mtime = stats.mtime.toString()
		if last_modified != mtime
			last_modified = mtime
			reboot(file)
			
		fs.stat file, handle_stats
		
	fs.stat file, handle_stats
	
	
child_proc = null

reboot =(file)->
	sys.log "Modification detected in #{file}. Restarting process." if POLL_TIMEOUT #hack to only print this after the first process is running
	if (child_proc and child_proc.pid)
		child_proc.kill() 
		child_proc = null
	else
		spawn_proc()
	
	
spawn_proc=->
	return if (child_proc and child_proc.pid)
	child_proc = cp.spawn PROCESS, ARGS
	child_proc.on 'exit', handle_exit
	child_proc.stdout.on 'data', (data)->sys.print data if data
	child_proc.stderr.on 'data', (data)->sys.print data if data
	
handle_exit=(code, signal)->
	if signal == "SIGTERM"
		spawn_proc()
	else
		child_proc = null
		
process.addListener "SIGTERM", ->
	console.log "killing proc"
	child_proc.kill() if child_proc.pid

first_spawn =->
	first =->
		POLL_TIMEOUT = TIMEOUT
		spawn_proc()
	setTimeout first, TIMEOUT

#-----------------#

IGNORE = [	'.git'
			'example/public'
			'watcher.coffee' #kinda pointless, since it won't restart itself
			/^\..+/
			/\.tmp$/
			]

VERBOSE = no

PROCESS = "coffee"
ARGS = ["paradigm.coffee"]
TIMEOUT = 300
  
first_spawn()
watch_dir '.'
sys.log "Watching."
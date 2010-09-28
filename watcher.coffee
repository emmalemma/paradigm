#TODO: does this actually catch every modification case?
#doesn't catch creating directories... low priority since an
#empty directory is usually not an interesting event

@Run = (Config) =>
	sys = require 'sys'
	fs = require 'fs'
	path = require 'path'
	cp = require 'child_process'
	
	log =(args...)->(console.log args...) if Config.verbose

	watched_files = []

	poll_timeout = 0
	poll = (f) ->
		(args...) ->
			setTimeout f, poll_timeout, args...
		
	watch_dir =(dir)->
		fs.readdir dir, handle_files = poll (err, files) ->
			if err #directory was deleted, reboot it
				return reboot(dir)
			for f in files
				fpath = path.join(dir, f)
				if fpath not in watched_files
					watch_file fpath, dir
				
			fs.readdir dir, handle_files
						

	watch_file =(file)->
		watched_files.push file
		last_modified = "new"
		for ig in Config.ignore
			if file.match ig or path.basename(file).match ig
				return log "Ignoring #{file}"
			
		log "Watching #{file}"
		fs.stat file, handle_stats = poll (err, stats) ->
			if err #this probably means the file was deleted
				return reboot(file)
				
			if stats.isDirectory()
				return watch_dir file
		
			mtime = stats.mtime.toString()
			if last_modified != mtime
				last_modified = mtime
				reboot(file)
			
			fs.stat file, handle_stats
		
	child_proc = null

	reboot =(file)->
		sys.log "Modification detected in #{file}. Restarting process." if poll_timeout #hack to only print this after the first process is running
		if (child_proc and child_proc.pid)
			child_proc.kill() 
			child_proc = null
		else
			spawn_proc()
	
	
	spawn_proc=->
		return if (child_proc and child_proc.pid)
		child_proc = cp.spawn Config.process, Config.args
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
			poll_timeout = Config.timeout
			spawn_proc()
		setTimeout first, Config.timeout

	#-----------------#

	first_spawn()
	watch_dir Config.dir
	sys.log "Watching."
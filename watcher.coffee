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
			setTimeout f, Config.timeout, args...
		
	watch_dir =(dir)->
		fs.readdir dir, handle_files = (err, files) ->				
			if err #directory was deleted, reboot it
				return reboot(dir)
			for f in files
				fpath = path.join(dir, f)
				if fpath not in watched_files
					watched_files.push watch_file fpath, dir
			fs.readdir dir, poll handle_files
						

	watch_file =(file)->
		for ig in Config.ignore
			return log "Ignoring #{file}" if file.match ig or path.basename(file).match ig
			
		fs.stat file, handle_stats = (err, stats) ->
			return reboot(file) if err #this probably means the file was deleted
			return watch_dir file if stats.isDirectory()
		
			mtime = stats.mtime.toString()
			
			if last? and last != mtime
				reboot(file)
			
			last = mtime
			fs.stat file, poll handle_stats
		log "Watching #{file}" and file
		
	child_proc = null

	reboot =(file)->
		sys.log "Modification detected in #{file}. Restarting process."
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
		if signal == "SIGTERM" #this means we killed it! or someone did...
			spawn_proc()
		else
			child_proc = null
		
	process.addListener "SIGTERM", ->
		console.log "killing proc"
		child_proc.kill() if child_proc.pid

	first_spawn = spawn_proc

	#-----------------#

	first_spawn()
	watch_dir Config.dir
	sys.log "Watching."
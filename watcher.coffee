#TODO: does this actually catch every modification case?
#doesn't catch creating directories... low priority since an
#empty directory is usually not an interesting event

sys = require 'sys'
fs = require 'fs'
path = require 'path'
cp = require 'child_process'

@Run = (Config) =>
	
	watched_files = []

	poll = (f) -> (args...) -> setTimeout f, Config.timeout, args...

	log =(args...)->(console.log args...) if Config.verbose
		
	watch_dir =(dir)->
		fs.readdir dir, handle_files = (err, files) ->				
			return reboot(dir) if err #directory was deleted, reboot it
			
			for f in files
				fpath = path.join(dir, f)
				if fpath not in watched_files
					watch_file fpath, dir
			fs.readdir dir, poll handle_files
						

	watch_file =(file)->
		watched_files.push file
		for ig in Config.ignore
			return log "Ignoring #{file}" if file.match ig or path.basename(file).match ig
			
		last = null
		fs.stat file, handle_stats = (err, stats) ->
			return reboot(file) if err #this probably means the file was deleted
			return watch_dir file if stats.isDirectory()			
			
			reboot(file) if last != mtime = stats.mtime.toString()
			last = mtime
			
			fs.stat file, poll handle_stats
		
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
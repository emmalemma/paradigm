#!/usr/bin/env coffee

BANNER = """
	Runs a paradigm appserver from the command line.
	
	Usage: 
		paradigm myapp.coffig
		paradigm --watch myapp.coffig
	
"""

SWITCHES = [
	['-w', '--watch', 'automatically restart the server on modification']
	['-h', '--help',            'display this help message']
]

fs = require 'fs'
path = require 'path'
global.$PARADIR = path.dirname(fs.realpathSync(__filename.split(" ")[0]))

global.$EXTDIR = path.join($PARADIR, 'ext/');

global.$LOCDIR = fs.realpathSync('.')
global.loc =(file)-> require path.join $LOCDIR, file

optparse = require 'optparse'

optionParser  = new optparse.OptionParser SWITCHES, BANNER

watch = no

optionParser.on 'watch', (opts) => watch = yes

opts = optionParser.parse process.argv

if not opts.length
	return puts optionParser.help()
else
	config = loc opts[0]
	if not (config and config.App and config.App.paradigm_version)
	    return console.log "That coffig does not appear to be a paradigm config file."
	else if watch
	    if config.Watcher
    		watcher = require path.join $PARADIR, 'watcher'
    		watcher.Run(config.Watcher)
    	else
    	    return console.log "That coffig does not have watcher settings."
	else
		server = require path.join $PARADIR, 'server'
		server.Run(config.App)
	
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

global.$PARADIR = path.dirname(fs.realpathSync(__filename))

global.$EXTDIR = path.join($PARADIR, 'ext/');
global.ext =(file)-> require path.join $EXTDIR, file

global.$LOCDIR = fs.realpathSync('.')
global.loc =(file)-> require path.join $LOCDIR, file

optparse = ext 'optparse'

optionParser  = new optparse.OptionParser SWITCHES, BANNER
opts = optionParser.parse process.argv

if not opts.arguments.length
	return puts optionParser.help()
else
	config = loc opts.arguments[0]
	if opts.watch
		watcher = require path.join $PARADIR, 'watcher'
		watcher.Run(config.Config.watcher)
	else
		server = require path.join $PARADIR, 'server'
		server.Run(config.Config)
	
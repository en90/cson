# Requires
fs = require('fs')
path = require('path')
CSON = require(path.join __dirname, '..', 'lib', 'cson')
opts = {}

# Helpers
outputHelp = ->
	process.stdout.write '''
		CSON CLI

		Usage:

			# Convert a JSON file into a CSON file
			json2cson in.json > out.cson

			# Same thing via piping
			cat in.json | json2cson > out.cson

			# Convert a CSON file into a JSON file
			cson2json in.cson > out.json

			# Same thing via piping
			cat in.cson | cson2json > out.json

		Options

			# Display this help
			--help

			# Indentation for CSON output
			--tabs
			--2spaces
			--4spaces

		'''

# Check arguments
if process.argv.indexOf('--help') isnt -1
	outputHelp()
	process.exit(0)

# Figure out conversion
if process.argv.toString().indexOf('cson2json') isnt -1
	conversion ='cson2json'
else if process.argv.toString().indexOf('json2cson') isnt -1
	conversion = 'json2cson'
	opts.indent =
		if (i = process.argv.indexOf('--tabs')) isnt -1
			'\t'
		else if (i = process.argv.indexOf('--2spaces')) isnt -1
			'  '
		else if (i = process.argv.indexOf('--4spaces')) isnt -1
			'    '
	if i isnt -1
		process.argv = process.argv.slice(0, i).concat process.argv.slice(i+1)
else
	process.stderr.write('Unknown conversion')
	process.exit(1)

# File conversion
if process.argv.length is 3
	filePath = process.argv[2]
	process.stdout.write(
		if conversion is 'cson2json'
			CSON.createJSONString CSON.parseCSONFile(filePath), opts
		else
			CSON.createCSONString CSON.parseJSONFile(filePath), opts
	)

# Try STDIN
else if process.argv.length is 2
	# Prepare
	data = ''
	useSTDIN = true
	convertSTDIN = ->
		process.stdout.write(
			if conversion is 'cson2json'
				CSON.createJSONString CSON.parseCSONString(data), opts
			else
				 CSON.createCSONString CSON.parseJSONString(data), opts
		)

	# Timeout if we don't have stdin
	timeoutFunction = ->
		# Clear timeout
		timeout = null

		# Skip if we are using stdin
		return  if data.replace(/\s+/, '')

		# Close stdin as we are not using it
		useSTDIN = false
		stdin.pause()

		# Render the document
		convertSTDIN()
	timeout = setTimeout(timeoutFunction, 1000)

	# Read stdin
	stdin = process.stdin
	stdin.resume()
	stdin.setEncoding('utf8')
	stdin.on 'data', (_data) ->
		data += _data.toString()
	process.stdin.on 'end', ->
		return  unless useSTDIN
		if timeout
			clearTimeout(timeout)
		convertSTDIN()

else
	outputHelp()
	process.exit(1)
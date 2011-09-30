# Nodeunit test suite.
#
# Run with:
#  % nodeunit test.coffee

{testCase} = require 'nodeunit'

{setTimeout, clearTimeout, setInterval, clearInterval, Date, wait, clearAll} = require './timers'

doneOnce = (test) ->
	done = false
	->
		throw new Error 'Already called method' if done
		done = true
		test.done()


module.exports = testCase
	setUp: (callback) ->
		clearAll()
		callback()

	'setTimeout(n) calls the method after n ms': (test) ->
		called = 0
		setTimeout (-> called++), 1000

		test.strictEqual called, 0, 'method called immediately'
		wait 999, ->
			test.strictEqual called, 0, 'method called too early'
			wait 1, ->
				test.strictEqual called, 1, 'method not called at the right time'
				wait 100000, ->
					test.strictEqual called, 1, 'method called again'
					test.done()

	'setTimeout(0) calls the method on next tick': (test) ->
		called = 0
		setTimeout (-> called++), 0

		test.strictEqual called, 0, 'Method called immediately'
		process.nextTick ->
			test.strictEqual called, 1, 'Method not called after nextTick'
			test.done()
	
	'setTimeout() calls methods at the right time': (test) ->
		start = Date.now()
		setTimeout (-> test.strictEqual Date.now(), start + 1000), 1000
		wait 100000, -> test.done()

	'Cancelling a timeout immediately works': (test) ->
		called = 0
		timeout = setTimeout (-> called++), 1000
		clearTimeout timeout
		wait 100000, ->
			test.strictEqual called, 0
			test.done()

	'Cancelling a timeout after some time works': (test) ->
		called = 0
		timeout = setTimeout (-> called++), 1000

		wait 999, ->
			clearTimeout timeout
			wait 100000, ->
				test.strictEqual called, 0
				test.done()
	
	# Intervals
	
	'Setting an interval works': (test) ->
		called = 0
		setInterval (-> called++), 1000

		wait 999, ->
			test.strictEqual called, 0, 'interval called too early'
			wait 1, ->
				test.strictEqual called, 1, 'interval not called at the right time'
				wait 5000, ->
					test.strictEqual called, 6, 'interval not called at the right time'
					test.done()
	
	'Cancelling an interval immediately works': (test) ->
		called = 0
		id = setInterval (-> called++), 1000
		clearInterval id
		wait 100000, ->
			test.strictEqual called, 0
			test.done()

	'Cancelling an interval after some time works': (test) ->
		called = 0
		id = setInterval (-> called++), 1000

		wait 1001, ->
			test.strictEqual called, 1
			clearInterval id
			wait 100000, ->
				test.strictEqual called, 1
				test.done()
	
	# Date

	'Date.now() returns a number': (test) ->
		start = Date.now()
		test.strictEqual typeof start, 'number'
		test.done()

	'Date.now() returns increasing values over time': (test) ->
		start = Date.now()
		wait 1000, ->
			end = Date.now()
			test.strictEqual end, start + 1000
			test.done()
	
	'Date.now()s value doesnt change with wait 0': (test) ->
		start = Date.now()
		wait 0, ->
			test.strictEqual Date.now(), start
			test.done()
	
	'new Date() returns a normal date object set to now': (test) ->
		d = new Date()
		test.ok d.toISOString()
		test.strictEqual d.getTime(), Date.now()
		test.done()

	'new Date(time) returns a normal date object': (test) ->
		d = new Date(1317391735268)
		test.strictEqual d.toISOString(), '2011-09-30T14:08:55.268Z'
		test.done()

	# Wait

	'wait is asynchronous': (test) ->
		v = true
		wait 1000, ->
			test.strictEqual v, false
			test.done()
		v = false
	
	'wait(0) is asynchronous': (test) ->
		v = true
		wait 0, ->
			test.strictEqual v, false
			test.done()
		v = false

	# clearAll
	
	'cleared stuff doesnt get called': (test) ->
		setTimeout (-> throw new Error 'should not be called'), 1000
		setInterval (-> throw new Error 'should not be called'), 1000
		setInterval (-> throw new Error 'should not be called'), 500

		wait 499, ->
			clearAll()
			wait 10000, ->
				test.done()
	

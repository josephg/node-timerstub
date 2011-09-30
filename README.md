# Timer stub

This is a super simple library to stub out the default javascript timer methods with something that
doesn't take any actual time to run. Because slow tests are for suckers!

If you're writing a library which uses timers (like [node-browserchannel](https://github.com/josephg/node-browserchannel)), its annoying to wait 30 seconds for your timeout event to fire.

## Install it

```
npm install timerstub
```

Add it to your package.json:

```json
  "dependencies": {
    "timerstub": "*"
  }
```


## Use it

Timer stub provides a replacement version of `setInterval`, `clearInterval`, `setTimeout`, `clearTimeout` and `Date.now` (through a wrapped `Date` function).

Instead of needing to spend real time waiting for your queued methods to be called, you can now just call `timerstub.wait 1000, -> done()` to 'wait' 1000 milliseconds. Any queued intervals and timeouts will be called (in order) before your callback is called. Oh yeah, and `Date.now()` will return the right values in all the callbacks. As far as your library is concerned, 1000 milliseconds *have really passed*. But your test runs as fast as your CPU can manage it.


## Example to copy+paste

In your library, write something like this:

```javascript
var setInterval = setInterval;
var clearInterval = clearInterval;
var setTimeout = setTimeout;
var clearTimeout = clearTimeout;
var Date = Date;

exports.setTimeFunctions = function(stubs) {
	setInterval = stubs.setInterval;
	setTimeout = stubs.setTimeout;
	clearInterval = stubs.clearInterval;
	clearTimeout = stubs.clearTimeout;
	Date = stubs.Date;
};


// Write the rest of your code as normal.

exports.coolstuff = function() {
	var timer = setTimeout(function(){...}, 1000);
	var start = new Date();
	var time = Date.now();
	clearTimeout(timer);
	// ...
}
```

In your test (nodeunit):

```coffeescript
timerstub = require 'timerstub'
mycoollibrary = require './mycoollibrary'

mycoollibrary.setTimeFunctions timerstub

module.export = testCase
	setUp: (callback) ->
		timerstub.clearAll() # This removes all queued timeouts and whatnot
		callback()

	'my cool test': (test) ->
		mycoollibrary.coolstuff()
		timerstub.wait 1000, ->
			# Now 1000 milliseconds of setInterval calls and stuff have run... instantly!
			test.strictEqual you.sexy, true
			test.done()
```

testtimers should be compatible with all the testing frameworks - it doesn't interfere with the
testing framework at all.

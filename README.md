# Timer stub

This is a super simple library to stub out the default javascript timer methods
with something that doesn't take any actual time to run. Because slow tests are
for suckers!

If you're writing a library which uses timers (like
    [node-browserchannel](https://github.com/josephg/node-browserchannel)), its
annoying to wait 30 seconds for your timeout event to fire.

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

Timer stub provides a replacement version of `setInterval`, `clearInterval`,
`setTimeout`, `clearTimeout` and `Date.now` (through a wrapped `Date`
function).

Instead of needing to spend real time waiting for your queued methods to be
called, you can now just call `timerstub.wait 1000, -> done()` to 'wait' 1000
milliseconds. Any queued intervals and timeouts will be called (in order)
before your callback is called. Oh yeah, and `Date.now()` will return the
right values in all the callbacks. As far as your library is concerned, 1000
milliseconds *have really passed*. But your test runs as fast as your CPU can
manage it.


## Example to copy+paste

In your library, write something like this:

```javascript
var setInterval, clearInterval, setTimeout, clearTimeout, Date;
function setTimeFunctions(source) {
  setInterval = source.setInterval;
  clearInterval = source.clearInterval;
  setTimeout = source.setTimeout;
  clearTimeout = source.clearTimeout;
  Date = source.Date;
};
setTimeFunctions((function() { return this; })()); // Use the normal ones.
exports.setTimeFunctions = setTimeFunctions;


// ... Then write the rest of your code as normal.
exports.coolstuff = function() {
	var timer = setTimeout(function() { foo(); }, 1000);
	var start = new Date();
	time = Date.now();
	clearTimeout(timer);
  // ...
}
```

In a testing framework like mocha:

```coffeescript
timerstub = require 'timerstub'
assert = require 'assert'
mycoollibrary = require './mycoollibrary'

mycoollibrary.setTimeFunctions timerstub

describe 'my cool thing'
	beforeEach ->
		timerstub.clearAll() # This removes all queued timeouts and whatnot

	it 'does cool stuff': (done) ->
		mycoollibrary.coolstuff()
		timerstub.wait 1000, ->
			# Now 1000 milliseconds of setInterval calls and stuff have run... instantly!
			assert.strictEqual you.sexy, true
			done()
```

In a parallel testing framework like expresso, simply add a call to
`timerstub.waitAll()` after all your tests have been scheduled. (In
expresso, that would be in a `beforeExit` block).

testtimers should be compatible with all the testing frameworks - it doesn't
interfere with the testing framework at all.


---

## MIT Licensed

Licensed under the standard MIT license:

Copyright 2011 Joseph Gentle.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

# Nodeunit test suite.
#
# Run with:
#  % nodeunit test.coffee

assert = require 'assert'
timers = require './timers'
# We'll override these global variables with local variables with the same names
{setTimeout, clearTimeout, setInterval, clearInterval, Date} = timers

doneOnce = (test) ->
  done = false
  ->
    throw new Error 'Already called method' if done
    done = true
    done()

describe 'timerstub', ->
  beforeEach ->
    timers.clearAll()

  # Timeout

  describe 'setTimeout', ->
    it '(n) calls the method after n ms', (done) ->
      called = 0
      setTimeout (-> called++), 1000

      assert.strictEqual called, 0, 'method called immediately'
      timers.wait 999, ->
        assert.strictEqual called, 0, 'method called too early'
        timers.wait 1, ->
          assert.strictEqual called, 1, 'method not called at the right time'
          timers.wait 100000, ->
            assert.strictEqual called, 1, 'method called again'
            done()

    it '(0) calls the method on next tick', (done) ->
      called = 0
      setTimeout (-> called++), 0

      assert.strictEqual called, 0, 'Method called immediately'
      setImmediate ->
        assert.strictEqual called, 1, 'Method not called after a setImmediate'
        done()
    
    it 'calls methods at the right time', (done) ->
      start = Date.now()
      setTimeout (-> assert.strictEqual Date.now(), start + 1000), 1000
      timers.wait 100000, -> done()

    it 'can be cancelled immediately', (done) ->
      called = 0
      timeout = setTimeout (-> called++), 1000
      clearTimeout timeout
      timers.wait 100000, ->
        assert.strictEqual called, 0
        done()

    it 'can be cancelled after some time', (done) ->
      called = 0
      timeout = setTimeout (-> called++), 1000

      timers.wait 999, ->
        clearTimeout timeout
        timers.wait 100000, ->
          assert.strictEqual called, 0
          done()
  
  # Intervals
  
  describe 'setInterval', ->
    it 'Setting an interval works', (done) ->
      called = 0
      setInterval (-> called++), 1000

      timers.wait 999, ->
        assert.strictEqual called, 0, 'interval called too early'
        timers.wait 1, ->
          assert.strictEqual called, 1, 'interval not called at the right time'
          timers.wait 5000, ->
            assert.strictEqual called, 6, 'interval not called at the right time'
            done()
    
    it 'can be cancelled immediately', (done) ->
      called = 0
      id = setInterval (-> called++), 1000
      clearInterval id
      timers.wait 100000, ->
        assert.strictEqual called, 0
        done()

    it 'can be cancelled after some time', (done) ->
      called = 0
      id = setInterval (-> called++), 1000

      timers.wait 1001, ->
        assert.strictEqual called, 1
        clearInterval id
        timers.wait 100000, ->
          assert.strictEqual called, 1
          done()

    it 'can cancel itself', (done) ->
      called = 0
      id = setInterval (-> called++; clearInterval id), 1000

      timers.wait 10000, ->
        assert.strictEqual called, 1
        done()

  # Date

  describe 'Date.now', ->
    it 'returns a number', ->
      start = Date.now()
      assert.strictEqual typeof start, 'number'

    it 'returns increasing values over time', (done) ->
      start = Date.now()
      timers.wait 1000, ->
        end = Date.now()
        assert.strictEqual end, start + 1000
        done()
    
    it 'does not change its value with timers.wait 0', (done) ->
      start = Date.now()
      timers.wait 0, ->
        assert.strictEqual Date.now(), start
        done()
    
    it 'returns a normal date object set to now', ->
      d = new Date()
      assert.ok d.toISOString()
      assert.strictEqual d.getTime(), Date.now()

    it 'returns a normal date object when called with new Date(time)', ->
      d = new Date(1317391735268)
      assert.strictEqual d.toISOString(), '2011-09-30T14:08:55.268Z'

  # Wait

  describe 'timers.wait', ->
    it '(n) is asynchronous', (done) ->
      v = true
      timers.wait 1000, ->
        assert.strictEqual v, false
        done()
      v = false
    
    it '(0) is asynchronous', (done) ->
      v = true
      timers.wait 0, ->
        assert.strictEqual v, false
        done()
      v = false
    
    it 'works with no callback', (done) ->
      setTimeout (->), 1000
      # This might crash now, or it might crash later...
      timers.wait 500
      process.nextTick ->
        timers.wait 1000
        process.nextTick ->
          done()

    it 'doesnt move the clock forward immediately', ->
      start = Date.now()
      timers.wait 500
      assert.strictEqual Date.now(), start

  # Wait All
  
  describe 'waitAll', ->
    it 'calls queued callback', (done) ->
      called = 0
      setTimeout (-> called++), 1000
      timers.waitAll ->
        assert.strictEqual called, 1
        done()
    
    it 'advances the date only as far as it need to', (done) ->
      start = Date.now()
      setTimeout (->), 1000
      timers.waitAll ->
        assert.strictEqual start + 1000, Date.now()
        done()

    it 'does nothing when nothing is queued', (done) ->
      start = Date.now()
      timers.waitAll ->
        assert.strictEqual start, Date.now()
        done()
    
    it 'does not crash when there is no callback', (done) ->
      start = Date.now()
      timers.waitAll()
      assert.strictEqual start, Date.now()
      done()
    
    it 'works with an interval', (done) ->
      called = false
      t = setInterval (->
        throw new Error 'already called' if called
        called = true
        clearInterval t
        ), 1000

      timers.waitAll ->
        assert.strictEqual called, true
        done()

  # clearAll
  
  describe 'clearAll', ->
    it 'cleared stuff doesnt get called', (done) ->
      setTimeout (-> throw new Error 'should not be called'), 1000
      setInterval (-> throw new Error 'should not be called'), 1000
      setInterval (-> throw new Error 'should not be called'), 500

      timers.wait 499, ->
        timers.clearAll()
        timers.wait 10000, ->
          done()
  

  # Integration
  
  describe 'integration', ->
    it 'lots of timers are called in order', (done) ->
      start = Date.now()
      called = 0
      for _ in [1..1000]
        do ->
          interval = Math.floor(Math.random() * 500)
          setTimeout (-> called++; assert.strictEqual Date.now(), start + interval, "int #{interval}"), interval

      timers.wait 500, ->
        assert.strictEqual called, 1000
        done()

    it 'lots of timers are called in order with timers.waitAll', (done) ->
      # Same as the above test except timers.waitAll() instead of timers.wait()
      start = Date.now()
      called = 0
      for _ in [1..1000]
        do ->
          interval = Math.floor(Math.random() * 500)
          setTimeout (-> called++; assert.strictEqual Date.now(), start + interval, "int #{interval}"), interval

      timers.waitAll ->
        assert.strictEqual called, 1000
        done()


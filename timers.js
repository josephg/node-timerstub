// We'll arbitrarily start the clock at 1 million milliseconds.
var now = 1000000;

// The queue contains {time, fn, repeat, id} commands which will be executed in
// order, at the time specified.
//
// Elements are stored as an array for convenience. Inserting is O(N) - but
// since this is intended for testing, it shouldn't matter too much. This
// should probably be replaced with a proper priority queue at some stage.
var queue = [];

var lastId = 0;

// Amount of fake time to advance with each function call we fire. Set with
// setAutoAdvance().
var autoAdvance = 0;

// Insert a new element in the queue. repeat = number of ms before the function
// should be called again, or 0 if the function should not repeat.
//
// Supplying an id is optional. Returns id.
var insert = function(time, fn, repeat, id) {
  var i = 0;

  while (i < queue.length && queue[i].time <= time)
    ++i;

  if (id == null)
    id = ++lastId;

  if (repeat == null)
    repeat = 0;

  queue.splice(i, 0, {time:time, fn:fn, repeat:repeat, id:id});
  return id;
};

exports.setTimeout = function(fn, timeout) {
  if (typeof fn === 'string') {
    // Supporting setTimeout("x++",1000) for compatibility with the spec, but
    // don't do it.
    fn = function() { return eval(fn); };
  }

  // setTimeout(fn, 0) should be called immediately even without calling wait.
  if (timeout === 0)
    wait(0);

  return insert(now + timeout, fn);
};

exports.setInterval = function(fn, timeout) {
  if (timeout === 0)
    throw new Error('Timer stubs dont support setInterval(fn, 0)');

  if (typeof fn === 'string') {
    // Again, for setInterval("x++",1000) - and again don't use it.
    fn = function() { return eval(fn); };
  }

  return insert(now + timeout, fn, timeout);
};

exports.clearTimeout = exports.clearInterval = function(id) {
  for (var i = 0; i < queue.length; i++) {
    if (queue[i].id === id) {
      // Splice out the named timer if we find it.
      queue.splice(i, 1);
      return;
    }
  }
};

exports.Date = function(time) {
  return new Date(time != null ? time : now);
};
exports.Date.now = function() { return now; };

// Immediately advance the clock, waiting a specified amount of time.
var wait = exports.wait = function(amt, callback) {
  var waitInternal = function(amt) {
    // This function calls itself recursively.
 
    if (!(typeof amt === 'number' && amt >= 0)) {
      throw new Error('amt must be a positive number');
    }

    if (queue.length > 0 && now + amt >= queue[0].time) {
      var command = queue.shift();

      // Only consume enough time to run the next command
      amt -= command.time - now;
      now = command.time;

      if (command.repeat) {
        insert(now + command.repeat, command.fn, command.repeat, command.id);
      }

      command.fn();
      
      amt += autoAdvance;

      // ... and requeue wait() with the remaining time in a setImmediate so we
      // don't starve the event loop.
      setImmediate(function() {
        waitInternal(amt, callback);
      });
    } else {
      // Done for now. Increment the clock and return.
      now += amt;

      if (callback) callback();
    }
  };

  setImmediate(function() {
    waitInternal(amt);
  });
};

exports.waitAll = function(callback) {
  // Only run one timeout per setImmediate event loop.
  if (queue.length === 0) {
    // Done!
    if (callback != null) setImmediate(callback);
  } else {
    exports.wait(queue[0].time - now, function() {
      exports.waitAll(callback);
    });
  }
};

exports.clearAll = function() {
  queue = [];
};

exports.setAutoAdvance = function(aa) {
  autoAdvance = aa;
}


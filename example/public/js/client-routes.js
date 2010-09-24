var $call, $callback, _i, _len, _ref, insert, routed_functions;
var __slice = Array.prototype.slice;
$call = function(function_name, args) {
  return jQuery.getJSON('/$/' + function_name.slice(1), (function() {
    if (args.length) {
      return JSON.stringify(args);
    }
  })(), $callback);
};
$callback = function(data, status, request) {
  if (data.callback) {
    console.log(data.callback);
    return window[data.callback](data);
  }
};
insert = function(data) {
  return console.log(data);
};
routed_functions = ["$routed_functions", "$datatoprint"];
_ref = routed_functions;
for (_i = 0, _len = _ref.length; _i < _len; _i++) {
  (function() {
    var f = _ref[_i];
    return (window[f] = function() {
      var args;
      args = __slice.call(arguments, 0);
      return $call("" + (f), args);
    });
  })();
}
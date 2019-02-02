const path = require('path');
const vm = require('vm');
const coffee = require('coffee-script');
const _eval = function(js, options) {
  if (options == null) {
    options = {};
  }
  const sandbox = vm.createContext();
  sandbox.exports = exports;
  sandbox.module = {
    exports: exports
  };
  sandbox.global = sandbox;
  sandbox.require = require;
  sandbox.__filename = options.filename || 'eval';
  sandbox.__dirname = path.dirname(sandbox.__filename);
  vm.runInContext(js, sandbox);
  return sandbox.module.exports;
};

module.exports = {
  json: function(content) {
    return JSON.parse(content);
  },
  js: function(content, opt) {
    return _eval(content, opt);
  },
  coffee: function(content, opt) {
    return coffee["eval"](content, opt);
  }
};
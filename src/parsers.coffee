path = require 'path'
vm = require 'vm'
coffee = require 'coffee-script'

_eval = (js, options = {}) ->
  sandbox = vm.createContext()
  sandbox.exports = exports
  sandbox.module = exports: exports
  sandbox.global = sandbox
  sandbox.require = require
  sandbox.__filename = options.filename or 'eval'
  sandbox.__dirname = path.dirname sandbox.__filename

  vm.runInContext js, sandbox

  sandbox.module.exports

module.exports =

  json: (content) -> JSON.parse(content)

  js: (content, opt) -> _eval content, opt

  coffee: (content, opt) -> coffee.eval content, opt

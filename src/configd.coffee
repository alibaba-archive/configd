chalk = require 'chalk'
Promise = require 'bluebird'
coffee = require 'coffee-script'
_ = require 'lodash'
path = require 'path'
fs = require 'fs'
vm = require 'vm'
Promise.promisifyAll fs

routers = require './routers'

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

_readFile = (source) ->

  _handler = routers.local

  configd._routes.some (route) ->
    if source.match route.route
      _handler = route.handler
      return true

  _handler source

  .then (data) ->

    return data unless toString.call(data) is '[object String]'

    # Parse the string format data
    # Guess format from ext name
    ext = path.extname(source).toLowerCase()

    switch ext
      when '.json' then data = JSON.parse(data)
      when '.js' then data = _eval data, filename: source
      when '.coffee' then data = coffee.eval data, filename: source
      else throw new Error("File extension #{ext} is not supported now!")

    throw new Error("Source content of #{source} is empty") unless data

    data

_writeFile = (filename, data) ->

  dir = path.dirname filename

  new Promise (resolve, reject) ->
    fs.exists dir, (exists) -> resolve exists
  .then (exists) ->
    return if exists
    fs.mkdirAsync dir

  .then ->
    fs.writeFileAsync filename, data

###*
 * Start define primary configd process
 * @param  {Array} sources - An array of sources
 * @param  {String} destination - Destination to write config data
 * @param  {Object} options - Other options
 * @return {Promise} configs - Merged configs
###
configd = (sources, destination, options) ->

  Promise.all sources.map _readFile

  .then (configs) ->

    config = configs.reduce (x, y) -> _.merge x, y

    _writeFile destination, JSON.stringify(config, null, 2)

    .then -> config

configd._routes = []

configd.route = (pattern, fn) ->
  configd._routes.push
    route: pattern
    handler: fn

# Set http router
configd.route /^http(s)?:\/\//, routers.http

# Set ssh router
configd.route /^ssh\:\/\//, routers.ssh

# Set git router
configd.route /^git\:\/\//, routers.git

# Export build-in routers
configd.routers = routers

module.exports = configd

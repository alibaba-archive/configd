chalk = require 'chalk'
Promise = require 'bluebird'
_ = require 'lodash'
routers = require './routers'
path = require 'path'
fs = require 'fs'
Promise.promisifyAll fs

_readFile = (source) ->

  _handler = null

  configd._routes.some (route) ->
    if source.match route.route
      _handler = route.handler
      return true

  unless toString.call(_handler) is '[object Function]'
    throw new Error("  Source of #{source} does not match any route")

  _handler source

  .then (data) ->

    return data unless toString.call(data) is '[object String]'

    # Parse the string format data
    # Guess format from ext name
    ext = path.extname(source).toLowerCase()

    switch ext
      when '.json' then data = JSON.parse(data)
      when '.js' then data = eval(data)
      else throw new Error("File extension #{ext} is not supported now!")

    data

_writeFile = (filename, data) ->

  dir = path.dirname filename

  fs.existsAsync dir

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

# Set default local router
configd.route /.*/, routers.local

# Export build-in routers
configd.routers = routers

module.exports = configd

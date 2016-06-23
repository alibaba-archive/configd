Promise = require 'bluebird'

_ = require 'lodash'
path = require 'path'
fs = require 'fs'
Promise.promisifyAll fs
globAsync = Promise.promisify(require('glob'))

readers = require './readers'
parsers = require './parsers'

_readers = []
_parsers = []

_readFile = (filename) ->

  _reader = readers.local
  _parser = null

  configd.readers.some (reader) ->
    if filename.match reader.pattern
      _reader = reader.handler
      return true

  configd.parsers.some (parser) ->
    if filename.match parser.pattern
      _parser = parser.handler
      return true

  _reader(filename).then (data) ->
    return data unless toString.call(data) is '[object String]'

    unless toString.call(_parser) is '[object Function]'
      throw new Error("Can not find parser for #{filename}")

    data = _parser(data, filename: filename)

    throw new Error("Content is empty! #{filename}") unless data

    data

_autoloadPlugins = (configd) ->
  return Promise.resolve() if configd._autoloaded

  Promise.reduce module.paths, (plugins, dirname) ->
    globAsync("#{dirname}/configd-*").then (_plugins) -> plugins.concat(_plugins)
  , []

  .then (plugins) ->
    # Don't repeat load same plugins
    plugins.forEach (pluginPath) ->
      basename = path.basename(pluginPath)
      unless configd._plugins[basename]
        try
          plugin = require(pluginPath)
          plugin(configd)
          configd._plugins[basename] = plugin
        catch err
          console.warn "Load plugin #{pluginPath} error: #{err.message}"

  .then -> configd._autoloaded = true

###*
 * Start define primary configd process
 * @param  {Array} sources - An array of sources
 * @param  {Object} options - Other options
 * @return {Promise} configs - Merged configs
###
configd = (sources, options) ->

  _autoloadPlugins configd

  .then ->
    Promise.reduce sources, (mergedConfig, sourceName) ->
      _readFile(sourceName).then (data) -> _.merge mergedConfig, data
    , {}

configd._autoloaded = false
configd._plugins = {}

configd.route = configd.reader = (pattern, fn) ->
  _readers.push
    pattern: pattern
    handler: fn

configd.parser = (pattern, fn) ->
  _parsers.push
    pattern: pattern
    handler: fn

Object.defineProperty configd, 'readers', get: -> _readers
Object.defineProperty configd, 'parsers', get: -> _parsers

# Set reader patterns
configd.reader /^http(s)?:\/\//, readers.http
configd.reader /^ssh\:\/\//, readers.ssh
configd.reader /^git\:\/\//, readers.git

# Set parser patterns
configd.parser /\.json$/i, parsers.json
configd.parser /\.js$/i, parsers.js
configd.parser /\.coffee$/i, parsers.coffee

module.exports = configd

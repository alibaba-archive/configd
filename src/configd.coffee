Promise = require 'bluebird'

_ = require 'lodash'
path = require 'path'
fs = require 'fs'
Promise.promisifyAll fs

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

###*
 * Start define primary configd process
 * @param  {Array} sources - An array of sources
 * @param  {Object} options - Other options
 * @return {Promise} configs - Merged configs
###
configd = (sources, options) ->

  Promise.all sources.map _readFile

  .then (configs) -> configs.reduce (x, y) -> _.merge x, y

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

fs = require 'fs'
Promise = require 'bluebird'
request = require 'request'
requestAsync = Promise.promisify request

module.exports =

  ###*
   * Default router, read local files
  ###
  local: (source) -> fs.readFileAsync source, encoding: 'UTF-8'

  ###*
   * Read remote file through ssh
  ###
  ssh: (source) ->

  ###*
   * Read file from git
  ###
  git: (source) ->

  ###*
   * Read from mongo database
  ###
  mongo: (source) ->

  ###*
   * Read file from http service
  ###
  http: (source) ->
    requestAsync
      url: source
      method: 'GET'
      headers: "User-Agent": "configd spider"
    .spread (res, body) ->
      unless res.statusCode >= 200 and res.statusCode < 300
        throw new Error("bad request #{res.statusCode} at #{source}")

      if res.headers['content-type']?.indexOf('application/json') > -1
        body = JSON.parse body

      body

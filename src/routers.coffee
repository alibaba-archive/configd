fs = require 'fs'
Promise = require 'bluebird'
request = require 'request'
{exec} = require 'child_process'
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
    # Strip protocol
    source = source[6..]
    [server, filename] = source.split(':')
    new Promise (resolve, reject) ->
      child = exec """
      ssh #{server} "cat #{filename}"
      """

      data = ""
      child.stdout.on 'data', (_data) ->
        data += _data

      child.on 'exit', (code) ->
        return reject(new Error("  The upload process exit with a non-zero value!")) unless code is 0
        resolve(data)

  ###*
   * Read file from git
  ###
  git: (source) ->

  ###*
   * Read from mongodb
  ###
  mongodb: (source) ->

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

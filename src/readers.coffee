fs = require 'fs'
path = require 'path'
os = require 'os'
Promise = require 'bluebird'
request = require 'request'
{exec} = require 'child_process'
requestAsync = Promise.promisify request

module.exports =

  ###*
   * Default reader, read local files
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
      child.stdout.on 'data', (_data) -> data += _data
      child.stderr.pipe process.stderr
      child.on 'exit', (code) ->
        return reject(new Error("The upload process exit with a non-zero value!")) unless code is 0
        resolve(data)

  ###*
   * Read file from git
  ###
  git: (source) ->
    # Strip protocal
    source = source[6..]
    [origins..., filename] = source.split(':')
    origin = origins.join ':'
    [origin, version] = origin.split '#'

    local = path.join os.tmpdir(), 'configd', path.basename(origin)
    version or= 'origin/master'

    new Promise (resolve, reject) ->
      fs.exists local, (exists) -> resolve exists

    .then (exists) ->
      if exists
        cmd = """
        cd #{local} && git fetch && git checkout #{version}
        """
      else
        cmd = """
        git clone #{origin} #{local}
        """

      new Promise (resolve, reject) ->
        child = exec cmd
        child.stdout.pipe process.stdout
        child.stderr.pipe process.stderr
        child.on 'exit', (code) ->
          return reject(new Error("The upload process exit with a non-zero value!")) unless code is 0
          resolve()

    .then -> fs.readFileAsync path.join(local, filename), encoding: 'UTF-8'

  ###*
   * Read file from http service
  ###
  http: (source) ->
    requestAsync
      url: source
      method: 'GET'
      headers: "User-Agent": "configd spider"
    .then (res) ->
      unless res.statusCode >= 200 and res.statusCode < 300
        throw new Error("bad request #{res.statusCode} at #{source}")

      if res.headers['content-type']?.indexOf('application/json') > -1
        body = JSON.parse res.body

      body

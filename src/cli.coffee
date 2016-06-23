path = require 'path'
commander = require 'commander'
chalk = require 'chalk'
Promise = require 'bluebird'
fs = require 'fs'
Promise.promisifyAll fs
mkdirpAsync = Promise.promisify(require 'mkdirp')

configd = require './configd'
pkg = require '../package.json'

_writeFile = (filename, data) ->

  dir = path.dirname filename

  new Promise (resolve, reject) ->
    fs.exists dir, (exists) -> resolve exists
  .then (exists) ->
    return if exists
    mkdirpAsync dir

  .then -> fs.writeFileAsync filename, data

module.exports = ->
  commander

  .version pkg.version

  .usage "source1 source2 protocol://source3 ... destination"

  .action (args...) ->
    unless args.length > 2
      console.warn chalk.yellow "  At least one source and one destination need to be provided!"
      return process.exit 1

    sources = args[...-2]
    destination = args[args.length - 2]
    options = args[args.length - 1]

    configd sources, destination, options

    .then (merged) -> _writeFile destination, JSON.stringify(merged, null, 2)

    .then (merged) ->
      console.log chalk.green "  Source #{sources} have merged into #{destination}"
      return process.exit 0

    .catch (err) ->
      console.error chalk.red "  #{err.message}"
      return process.exit 2

  .parse process.argv

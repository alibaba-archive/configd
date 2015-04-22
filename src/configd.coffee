chalk = require 'chalk'
Promise = require 'bluebird'
_ = require 'lodash'
path = require 'path'
fs = require 'fs'
Promise.promisifyAll fs

_readFile = (source) ->

  fs.readFileAsync source, encoding: 'UTF-8'

  .then (data) ->
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

module.exports = configd = (sources, destination, options) ->

  Promise.all sources.map _readFile

  .then (configs) ->

    config = configs.reduce (x, y) -> _.merge x, y

    _writeFile destination, JSON.stringify(config, null, 2)

    .then -> config

should = require 'should'
fs = require 'fs'
Promise = require 'bluebird'
express = require 'express'
Promise.promisifyAll fs

configd = require '../src/configd'

app = express()

app.get '/http.json', (req, res) -> res.send(require("./assets/http.json"))

app.listen 3333

describe 'Main', ->

  it 'should read configs from local sources and merge them into destination', (done) ->

    configd [
      "#{__dirname}/assets/default.json"
      "#{__dirname}/assets/custom.json"  # Read from json
      "#{__dirname}/assets/ext.js"  # Read from js file
      "http://localhost:3333/http.json"  # Read form http/https server
    ], "#{__dirname}/dest/merged.json"

    .then (merged) ->

      fs.readFileAsync "#{__dirname}/dest/merged.json", encoding: 'UTF-8'

    .then (merged) ->

      merged = JSON.parse merged

      merged.should.eql
        app: 'awesome app'
        db: 'mongodb://localhost:27017'
        redis: '127.0.0.1'
        port: 3333

      done()

    .catch done

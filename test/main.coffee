should = require 'should'
fs = require 'fs'
Promise = require 'bluebird'
Promise.promisifyAll fs

configd = require '../src/configd'

describe 'Main', ->

  it 'should read configs from local sources and merge them into destination', (done) ->

    configd [
      "#{__dirname}/assets/default.json"
      "#{__dirname}/assets/custom.json"
      "#{__dirname}/assets/ext.js"
    ], "#{__dirname}/dest/merged.json"

    .then (merged) ->

      fs.readFileAsync "#{__dirname}/dest/merged.json", encoding: 'UTF-8'

    .then (merged) ->

      merged = JSON.parse merged

      merged.should.eql
        app: 'awesome app'
        db: 'mongodb://localhost:27017'
        redis: '127.0.0.1'

      done()

    .catch done

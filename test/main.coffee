should = require 'should'
fs = require 'fs'
Promise = require 'bluebird'
express = require 'express'
{exec} = require 'child_process'
Promise.promisifyAll fs

configd = require '../src/configd'
config = require './config'

app = express()

app.get '/http.json', (req, res) -> res.send(require("./assets/http.json"))

app.listen 3333

describe 'Main', ->

  it 'should read configs from local sources and merge them into destination', (done) ->

    sources = [
      "#{__dirname}/assets/default.json"
      "#{__dirname}/assets/custom.json"  # Read from json
      "#{__dirname}/assets/ext.js"  # Read from js file
      "http://localhost:3333/http.json"  # Read form http/https server
      # "git://https://github.com/teambition/configd#HEAD:git.json"
    ]

    mergedConfig =
      app: 'awesome app'
      db: 'mongodb://localhost:27017'
      redis: '127.0.0.1'
      port: 3333

    if config.ssh
      $prepare = new Promise (resolve, reject) ->
        # Upload ssh.json to remote server
        sources.push "ssh://#{config.ssh}:~/ssh.json"
        mergedConfig["ssh-key"] = "key"
        child = exec "scp #{__dirname}/assets/ssh.json #{config.ssh}:~/ssh.json"
        child.stdout.pipe process.stdout
        child.on 'exit', (code) ->
          return reject(new Error("  The upload process exit with a non-zero value!")) unless code is 0
          resolve()
    else
      console.warn "  Set up your ssh server to test ssh router"
      $prepare = Promise.resolve()

    $prepare.then ->

      configd sources, "#{__dirname}/dest/merged.json"

    .then (merged) ->

      fs.readFileAsync "#{__dirname}/dest/merged.json", encoding: 'UTF-8'

    .then (merged) ->

      merged = JSON.parse merged

      merged.should.eql mergedConfig

      done()

    .catch done

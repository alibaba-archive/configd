commander = require 'commander'
chalk = require 'chalk'
configd = require './configd'
pkg = require '../package.json'

module.exports = ->
  commander

  .version pkg.version

  .action (args...) ->
    unless args.length > 2
      console.warn chalk.yellow "  At least one source and one destination need to be provided!"
      return process.exit 1

    sources = args[...-2]
    destination = args[args.length - 2]
    options = args[args.length - 1]

    configd sources, destination, options

    .then (merged) ->
      console.log chalk.green "  Source #{sources} have merged into #{destination}"
      return process.exit 0

    .catch (err) ->
      console.error chalk.red "  #{err.message}"
      return process.exit 2

  .parse process.argv

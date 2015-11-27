{spawn} = require 'child_process'

module.exports =
class FuseLauncher
  constructor: (@fusePath) ->

  run: (args) ->
    return spawn @fusePath, args

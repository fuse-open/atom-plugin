{Disposable} = require 'atom'
DaemonConnection = require './daemonConnection'

module.exports =
class Daemon extends Disposable
  constructor: (daemonCommand) ->
    super(@dispose)
    @daemonConnection = new DaemonConnection daemonCommand

  broadcastEvent: (event) =>
    @daemonConnection.send event

  dispose: =>

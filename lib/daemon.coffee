{Disposable} = require 'atom'
DaemonConnection = require './daemonConnection'

module.exports =
class Daemon extends Disposable
  lastRequestId: 0
  requestsInAir: {}

  constructor: (daemonCommand) ->
    super(@dispose)
    @daemonConnection = new DaemonConnection(daemonCommand, @messageFromDaemon)

  broadcastEvent: (event) =>
    @daemonConnection.send(event.messageType, event.serialize())

  messageFromDaemon: (msg) =>
    if(msg.messageType == "Response")
      request = @requestsInAir[msg.id]
      if not request?
        console.log(
          'fuse: Got response however response id does not match any request.')

      request.callback(msg)

  request: (request, callback) =>
    if not callback?
      throw new Error("Expected callback to not be undefined.")

    id = @getUniqueRequestId()
    serializedMsg = request.serialize(id)
    @requestsInAir[id] = { callback: callback }
    @daemonConnection.send(request.messageType, serializedMsg)

  getUniqueRequestId: ->
    return @lastRequestId++

  dispose: =>
    @daemonConnection.dispose()

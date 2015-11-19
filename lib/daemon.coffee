{Disposable} = require 'atom'
DaemonConnection = require './daemonConnection'

module.exports =
class Daemon extends Disposable
  lastRequestId: 0
  requestsInAir: []

  constructor: (daemonCommand) ->
    super(@dispose)
    @daemonConnection = new DaemonConnection(daemonCommand, (msg) =>
      console.log(msg.messageType))

  broadcastEvent: (event) =>
    @daemonConnection.send(event.messageType, event.serialize())

  request: (request) =>
    id = @getUniqueRequestId()
    serializedMsg = request.serialize(id)
    @requestsInAir.push { name: request.name, id: id }
    @daemonConnection.send(request.messageType, serializedMsg)

  getUniqueRequestId: ->
    return @lastRequestId++

  dispose: =>
    @daemonConnection.dispose()

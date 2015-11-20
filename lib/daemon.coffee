{Disposable} = require 'atom'
DaemonConnection = require './daemonConnection'

module.exports =
class Daemon extends Disposable
  lastRequestId: 0
  daemonConnection: null
  requestsInAir: {}

  constructor: (daemonCommand) ->
    super(@dispose)
    @daemonConnection = new DaemonReconnector(daemonCommand, @messageFromDaemon)

  broadcastEvent: (event) =>
    @daemonConnection.send(event.messageType, event.serialize())

  messageFromDaemon: (msg) =>
    if(msg.messageType == "Response")
      request = @requestsInAir[msg.id]
      if not request?
        console.log(
          'fuse: Got response however response id does not match any request.')
        return

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

  class DaemonReconnector extends Disposable
    constructor: (@daemonCommand, @msgReceivedCallback) ->
      super(@dispose)
      @daemonConnection = @connect()

    connect: ->
      return new DaemonConnection(@daemonCommand, @msgReceivedCallback, @onLostConnection)

    send: (msgType, serializedMsg) =>
      if not @daemonConnection?
        console.log('fuse: Connects to daemon again.')
        @daemonConnection = @connect()

      @daemonConnection.send(msgType, serializedMsg)

    onLostConnection: =>
      @daemonConnection = null

    dispose: =>
      @daemonConnection.dispose()
      @daemonConnection = null

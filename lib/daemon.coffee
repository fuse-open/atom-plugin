{Disposable, Emitter} = require 'atom'
DaemonConnection = require './daemonConnection'
{Event, Response, Request} = require './messageTypes'
{SubscribeRequest} = require './messages'

module.exports =
class Daemon extends Disposable
  uniqueId: 0
  daemonConnection: null
  requestsInAir: {}
  eventSubscriptions: []

  constructor: (daemonCommand) ->
    super(@dispose)
    @emitter = new Emitter
    @daemonConnection = new DaemonReconnector(
      daemonCommand,
      @messageFromDaemon,
      () =>
        tmpCopy = @eventSubscriptions.splice(0)
        @eventSubscriptions = []
        @observeBroadcastedEvents(sub.filter, sub.replay, sub.callback) for sub in tmpCopy
    )

  broadcastEvent: (event) ->
    @daemonConnection.send(event.messageType, event.serialize())

  observeBroadcastedEvents: (filter, replay, callback) =>
    subscriptionId = @getUniqueId()
    subscribeRequest = new SubscribeRequest {
      filter: filter,
      replay: replay,
      subscriptionId: subscriptionId
    }

    @request(subscribeRequest, (response) ->
        if response.status != "Success"
          console.log("Failed to subscribe to events. " +
            "Filter: #{filter}, Replay: #{replay}")
    )

    @eventSubscriptions.push filter: filter, replay: replay, callback: callback

    return @emitter.on 'new-event', (msg) =>
      callback(msg) if msg.subscriptionId == subscriptionId

  messageFromDaemon: (msg) =>
    if msg instanceof Response
      request = @requestsInAir[msg.id]
      if not request?
        console.log(
          'fuse: Got response however response id does not match any request.')
        return

      request.callback(msg)
    else if msg instanceof Event
      @emitter.emit 'new-event', msg

  request: (request, callback) =>
    if not callback?
      throw new Error("Expected callback to not be undefined.")

    id = @getUniqueId()
    serializedMsg = request.serialize(id)
    @requestsInAir[id] = { callback: callback }
    @daemonConnection.send(request.messageType, serializedMsg)

  getUniqueId: ->
    return @uniqueId++

  dispose: =>
    @eventSubscriptions = []
    @daemonConnection.dispose()

  class DaemonReconnector extends Disposable
    constructor: (@daemonCommand, @msgReceivedCallback, @onConnected) ->
      super(@dispose)
      @connect()

    connect: ->
      @daemonConnection = new DaemonConnection(@daemonCommand, @msgReceivedCallback, @onLostConnection)
      @onConnected?()

    send: (msgType, serializedMsg) =>
      if not @daemonConnection?
        console.log('fuse: Connects to daemon again.')
        @connect()

      @daemonConnection.send(msgType, serializedMsg)

    onLostConnection: =>
      @daemonConnection = null

    dispose: =>
      @daemonConnection?.dispose()
      @daemonConnection = null

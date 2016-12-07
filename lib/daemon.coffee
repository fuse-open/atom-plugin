{Disposable, Emitter} = require 'atom'
DaemonConnection = require './daemonConnection'
{Event, Response, Request} = require './messageTypes'
{SubscribeRequest, PublishServiceRequest} = require './messages'

module.exports =
class Daemon extends Disposable
  uniqueId: 0
  daemonConnection: null
  requestsInAir: {}
  requestListeners: {}
  eventSubscriptions: []

  constructor: (fuseLauncher) ->
    super(@dispose)
    @emitter = new Emitter
    @daemonConnection = new DaemonReconnector(
      fuseLauncher,
      @messageFromDaemon,
      () =>
        tmpCopy = @eventSubscriptions.splice(0)
        @eventSubscriptions = []
        @observeBroadcastedEvents(sub.filter, sub.replay, sub.callback) for sub in tmpCopy
        for own requestName, callback of @requestListeners
          @registerRequestListener requestName, callback
    )

  broadcastEvent: (event) ->
    @daemonConnection.send(event.messageType, event.serialize())

  registerRequestListener: (requestName, callback) =>
    publishServiceRequest = new PublishServiceRequest {
      requestNames: [ requestName ]
    }

    @request(publishServiceRequest, (response) =>
      if response.status != "Success"
        console.log "fuse: Failed to register " + requestName " request"
      else
        @requestListeners[requestName] = callback
        console.log "fuse: Successfully registered " + requestName  + " request"
    )

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

    else if msg instanceof Request
      callback = @requestListeners[msg.name]
      if callback?
        callback msg, (response) =>
          console.log("Sending response:")
          @daemonConnection.send response.messageType, response.serialize()
      else
        console.log('fuse: Received request with name ' + msg.name + ' having no registered listener')

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
    constructor: (@fuseLauncher, @msgReceivedCallback, @onConnected) ->
      super(@dispose)
      @daemonConnection = @connect()

    connect: ->
      try
        connection = new DaemonConnection(@fuseLauncher, @msgReceivedCallback, @onLostConnection)
        @onConnected?()
        return connection
      catch error
        console.log error

    send: (msgType, serializedMsg) =>
      if not @daemonConnection?
        console.log('fuse: Connects to daemon again.')
        @daemonConnection = @connect()

      @daemonConnection.send(msgType, serializedMsg)

    onLostConnection: =>
      @daemonConnection = null

    dispose: =>
      @daemonConnection?.dispose()
      @daemonConnection = null

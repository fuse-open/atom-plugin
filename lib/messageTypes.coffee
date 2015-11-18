module.exports =
Message:
  class Message
    constructor: (@messageType) ->
Event:
  class Event extends Message
    constructor: (@name) ->
      super "Event"

    serialize: (data) ->
      return JSON.stringify({
        Name: @name,
        Data: data
      })

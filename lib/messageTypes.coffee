module.exports =
Message:
  class Message
    constructor: (@messageType) ->

    @deserialize: (msgType, json) ->
      if msgType == "Event"
        return Event.deserialize(json)
      else if msgType == "Request"
        return Request.deserialize(json)
      else if msgType == "Response"
        return Response.deserialize(json)
      else
        console.log("fuse: Unknown message type.")
Event:
  class Event extends Message
    constructor: (@name, @data) ->
      super "Event"

    serialize: ->
      return JSON.stringify({
        Name: @name,
        Data: @data
      })

    @deserialize: (json) ->
      evtObj = JSON.parse(json)
      event = new Event(evtObj.Name)
      event["data"] = evtObj.Data
      return event
Request:
  class Request extends Message
    constructor: (@name, @arguments) ->
      super "Request"

    serialize: (id) ->
      return JSON.stringify({
        Name: @name,
        Id: id,
        Arguments: @arguments
      })

    @deserialize: (json) ->
      reqObj = JSON.parse(json)
      request = new Request(reqObj.Name, reqObj.Arguments)
      request["id"] = reqObj.Id
      return request
Response:
  class Response extends Message
    constructor: (@id, @status, @errors, @result) ->
      super "Response"

    serialize: ->
      return JSON.stringify({
        Id: @id
        Result: @result
      })

    @deserialize: (json) ->
      resObj = JSON.parse(json)
      response = new Response(resObj.Id,
        resObj.Status,
        resObj.Errors,
        resObj.Result)
      return response

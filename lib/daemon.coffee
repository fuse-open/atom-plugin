{Disposable} = require 'atom'

module.exports =
class Daemon extends Disposable
  constructor: ->
    super(@dispose)

  broadcastEvent: (event) =>
    console.log(event.serialize())

  dispose: =>
    

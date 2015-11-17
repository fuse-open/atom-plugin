module.exports =
class Daemon
  construtor: ->

  broadcastEvent: (event) =>
    console.log(event.path, event.cursorPos)

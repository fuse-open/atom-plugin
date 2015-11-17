module.exports =
class SelectionChangedEvent
  constructor: (args) ->
    {@path, @text, @cursorPos} = args

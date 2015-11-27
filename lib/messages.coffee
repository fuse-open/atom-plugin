{Event, Request} = require './messageTypes.coffee'

module.exports =
MessageHelper:
  class MessageHelper
    @convertToCaretPos: (point) ->
      return { Line: point.row + 1, Character: point.column + 1 }

SelectionChangedEvent:
  # Public: {SelectionChangedEvent} is a datastructure that can be sent to daemon.
  class SelectionChangedEvent extends Event
    # Creates a new {SelectionChangedEvent}.
    # data - An object consisting of:
    #   path - The {string} path of file where selection happened.
    #   text - The {string} text of the file selected
    #           (this may differ from what is saved to disk).
    #   caretPosition - A {Point} storing caret position in file.
    constructor: (data) ->
      super "Fuse.Preview.SelectionChanged", {
        Path: data.path,
        Text: data.text,
        CaretPosition: MessageHelper.convertToCaretPos(data.caretPosition)
      }

SubscribeRequest:
  class SubscribeRequest extends Request
    constructor: (args) ->
      super "Subscribe", {
        Filter: args.filter,
        Replay: args.replay,
        SubscriptionId: args.subscriptionId
      }

GetCodeSuggestionsRequest:
  class GetCodeSuggestionsRequest extends Request
    constructor: (args) ->      
      super "Fuse.GetCodeSuggestions", {
        Text: args.text,
        Path: args.path,
        SyntaxType: args.syntaxType,
        CaretPosition: MessageHelper.convertToCaretPos(args.caretPosition)
      }

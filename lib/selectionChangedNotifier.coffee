{Event} = require './messageTypes.coffee'
{Disposable} = require 'atom'

# Public: The {SelectionChangedNotifier} will listen for
# cursor position changes done in an UX file.
# These changes are then sent as events to the Fuse daemon.
module.exports =
class SelectionChangedNotifier extends Disposable
  textEditorSub = null

  # Public: Creates a new {SelectionChangedNotifier}.
  # Constructor will start listening.
  # Dispose {SelectionChangedNotifier} to stop listening.
  #
  # daemon - An reference to an instance of type {Daemon}.
  constructor: (@daemon) ->
    super(@dispose)

    @textEditorSub = atom.workspace.observeTextEditors (editor) =>
      if editor.getGrammar().name is "UX"
        cursorChangeSub = editor.onDidChangeCursorPosition (event) =>
          @cursorPositionChangedInUxEditor(editor, event)

        destroySub = editor.onDidDestroy ->
          cursorChangeSub.dispose()
          destroySub.dispose()

  cursorPositionChangedInUxEditor: (editor, event) ->
    path = editor.getPath()
    text = editor.getText()
    cursorPos = event.newBufferPosition
    @daemon.broadcastEvent(
      new SelectionChangedEvent(
        path: path,
        text: text,
        caretPosition: cursorPos))

  dispose: =>
    @textEditorSub.dispose()

  # Public: {SelectionChangedEvent} is a datastructure that can be sent to daemon.
  class SelectionChangedEvent extends Event
    # Creates a new {SelectionChangedEvent}.
    # data - An object consisting of:
    #   path - The {string} path of file where selection happened.
    #   text - The {string} text of the file selected
    #           (this may differ from what is saved to disk).
    #   caretPosition - A {Point} storing caret position in file.
    constructor: (data) ->
      super "Fuse.Preview.SelectionChanged"
      {@path, @text, @caretPosition} = data

    serialize: =>
      caretPosition = {
        Line: @caretPosition.row + 1,
        Character: @caretPosition.column + 1
      }
      
      return super({
        Path: @path,
        Text: @text,
        CaretPosition: caretPosition
      })

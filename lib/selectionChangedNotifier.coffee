{SelectionChangedEvent} = require './messages'
{Disposable, CompositeDisposable} = require 'atom'

# Public: The {SelectionChangedNotifier} will listen for
# cursor position changes done in an UX file.
# These changes are then sent as events to the Fuse daemon.
module.exports =
class SelectionChangedNotifier extends Disposable
  textEditorSub = null
  fuseSelectionSub = null

  # Public: Creates a new {SelectionChangedNotifier}.
  # Constructor will start listening.
  # Dispose {SelectionChangedNotifier} to stop listening.
  #
  # daemon - An reference to an instance of type {Daemon}.
  constructor: (@daemon) ->
    super(@dispose)

    @fuseSelectionSub = atom.config.observe 'fuse.fuseSelection', (turnOnSelection) =>
      @textEditorSub?.dispose()
      if turnOnSelection
        @textEditorSub = @hookSelectionObserver()

  hookSelectionObserver: () ->
    subscriptions = new CompositeDisposable
    subscriptions.add atom.workspace.observeTextEditors (editor) =>
      if editor.getGrammar().name is "UX"
        cursorChangeSub = editor.onDidChangeCursorPosition (event) =>
          @cursorPositionChangedInUxEditor(editor, event)

        destroySub = editor.onDidDestroy ->
          cursorChangeSub.dispose()
          destroySub.dispose()

        subscriptions.add cursorChangeSub
        subscriptions.add destroySub

    return subscriptions

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
    @fuseSelectionSub.dispose()
    @textEditorSub?.dispose()

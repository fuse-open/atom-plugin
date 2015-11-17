SelectionChangedEvent = require './selectionChangedEvent'
Daemon = require './daemon'
{CompositeDisposable} = require 'atom'

module.exports = Fuse =
  subscriptions: null
  daemon: null

  activate: (state) ->
    @daemon = new Daemon
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
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
      new SelectionChangedEvent(path: path, text: text, cursorPos: cursorPos))

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->

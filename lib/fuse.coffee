SelectionChangedNotifier = require './selectionChangedNotifier'
{FocusEditorListener} = require './focusEditor'
Daemon = require './daemon'
UXProvider = require './uxProvider'
BuildObserver = require './buildObserver'
{ErrorListView, ErrorListModel} = require './errorListView'
{SubscribeRequest,FocusDesignerRequest} = require './messages'
process = require 'process'
{CompositeDisposable, Disposable, Point} = require 'atom'
FuseBottomPanel = require './fuseBottomPanel'
FuseLauncher = require './fuseLauncher'
Preview = require './preview'
Path = require 'path'
{OutputView, LogEvent, OutputModel} = require './outputView'
AutoCloser = require './autoclose'

module.exports = Fuse =
  subscriptions: null
  daemon: null
  autoCloser: null

  config:
    fuseCommand:
      type: 'string'
      default: 'fuse'
      description: 'Set absolute path/name of fuse executable.'
    fuseSelection:
      type: 'boolean'
      default: 'true'
      description: 'Enable selection of UX tags reflected in preview based on caret position.'
    autocloseEnabled:
      type: 'boolean',
      default: true,
      description: 'Enable auto closing of UX tags.'

  activate: (state) ->
    console.log('fuse: Starting fuse.')
    if process.platform == 'darwin'
      process.env["PATH"] += ':/usr/local/bin'

    fuseLauncher = new FuseLauncher atom.config.get('fuse.fuseCommand')

    @subscriptions = new CompositeDisposable
    @daemon = new Daemon(fuseLauncher)
    @subscriptions.add @daemon
    @subscriptions.add new SelectionChangedNotifier @daemon

    @fuseBottomPanel = new FuseBottomPanel state.fuseBottomPanel
    atom.workspace.addBottomPanel(item: @fuseBottomPanel, visibility: false, priority: 100)

    @subscriptions.add atom.commands.add 'atom-workspace', 'fuse:panel': =>
      @fuseBottomPanel.toggle()

    buildObserver = new BuildObserver @daemon.observeBroadcastedEvents
    @subscriptions.add buildObserver

    focusEditorListener = new FocusEditorListener @daemon.registerRequestListener

    errorlistModel = new ErrorListModel buildObserver
    outputModel = new OutputModel buildObserver

    @fuseBottomPanel.addTab 'Error List', ->
      new ErrorListView errorlistModel
    @fuseBottomPanel.addTab 'Output', ->
      new OutputView outputModel

    @subscriptions.add errorlistModel.onFocusChanged () =>
      @fuseBottomPanel.focusTab 'Error List'

    @subscriptions.add outputModel.onFocusChanged () =>
      @fuseBottomPanel.focusTab 'Output'

    @subscriptions.add atom.commands.add 'atom-workspace', 'fuse:locate-in-designer': =>
      Fuse.locateInDesigner(fuseLauncher, @daemon, outputModel)

    @subscriptions.add atom.commands.add 'atom-workspace', 'fuse:preview-local': ->
      textEditor = @getModel().getActiveTextEditor()
      Fuse.previewWithOutput(fuseLauncher, 'local', Path.dirname(textEditor.getPath()), outputModel)

    @subscriptions.add atom.commands.add 'atom-workspace', 'fuse:preview-android': ->
      textEditor = @getModel().getActiveTextEditor()
      Fuse.previewWithOutput(fuseLauncher, 'android', Path.dirname(textEditor.getPath()), outputModel)

    @subscriptions.add atom.commands.add 'atom-workspace', 'fuse:preview-ios': ->
      textEditor = @getModel().getActiveTextEditor()
      Fuse.previewWithOutput(fuseLauncher, 'ios', Path.dirname(textEditor.getPath()), outputModel)

    @uxProvider = new UXProvider @daemon

    @autoCloser = new AutoCloser

  previewWithOutput: (fuseLauncher, target, path, output) ->
    p = Preview.run(fuseLauncher, target, path)
    output.clear()
    output.focus()

    p.observeOutput (msg) ->
      output.log new LogEvent(message: msg)
    p.observeError (msg) ->
      output.log new LogEvent(message: msg)

  locateInDesigner: (fuseLauncher, daemon, outputModel) ->
    console.log "fuse: Runnning locate in designer command"
    textEditor = atom.workspace.getActiveTextEditor()
    if textEditor?
      console.log "fuse: Sending locate in designer request for " + textEditor.getPath()
      position = textEditor.getCursorBufferPosition()
      message = new FocusDesignerRequest {
        file: textEditor.getPath(),
        line: position.row + 1,
        column: position.column + 1
      }
      daemon.request message, (response) ->
        console.log "Got response for message"
        console.dir response
        if response.status == "Unhandled"
          Fuse.previewWithOutput(fuseLauncher, 'local', Path.dirname(textEditor.getPath()), outputModel)

  getProvider: ->
    @uxProvider

  deactivate: ->
    @subscriptions?.dispose()
    @fuseBottomPanel?.destroy()
    @autoCloser?.deactivate()

  serialize: ->
    fuseBottomPanel: @fuseBottomPanel?.serialize()

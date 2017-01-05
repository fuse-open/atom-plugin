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

module.exports = Fuse =
  currentEditor: null
  action: null
  extension: ''
  enabledFileExtensions: []
  subscriptions: null
  daemon: null

  config:
    fuseCommand:
      type: 'string'
      default: 'fuse'
      description: 'Set absolute path/name of fuse executable.'
    fuseSelection:
      type: 'boolean'
      default: 'true'
      description: 'Enable selection of UX tags reflected in preview based on caret position.'
    enabledFileExtensions:
      type: 'array',
      default: ['ux'],
      description: 'Enabled only in UX files'


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

    # AUTOCLOSE STUFF

    atom.config.observe 'fuse.enabledFileExtensions', (value) =>
      @enabledFileExtensions = value

    @currentEditor = atom.workspace.getActiveTextEditor()
    if @currentEditor
      @action = @currentEditor.onDidInsertText (event) =>
        @_closeTag(event)
    @_getFileExtension()
    atom.workspace.onDidChangeActivePaneItem (paneItem) =>
      @_paneItemChanged(paneItem)

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

    if @action then @action.disposalAction()
    @subscriptions.dispose()

  serialize: ->
    fuseBottomPanel: @fuseBottomPanel?.serialize()

  _getFileExtension: ->
    filename = @currentEditor?.getFileName?()
    @extension = filename?.substr filename?.lastIndexOf('.') + 1

  _paneItemChanged: (paneItem) ->
    if !paneItem then return

    if @action then @action.disposalAction()
    @currentEditor = paneItem
    @_getFileExtension()
    if @currentEditor.onDidInsertText
      @action = @currentEditor.onDidInsertText (event) =>
        @_closeTag(event)

  _addIndent: (range) ->
    {start, end} = range
    buffer = @currentEditor.buffer
    lineBefore = buffer.getLines()[start.row]
    lineAfter = buffer.getLines()[end.row]
    content = lineBefore.substr(lineBefore.lastIndexOf('<')) + '\n' + lineAfter
    regex = ///
              ^.*\<([a-zA-Z-_]+)(\s.+)?\>
              \n
              \s*\<\/\1\>.*
            ///

    if regex.test content
      @currentEditor.insertNewlineAbove()
      @currentEditor.insertText('  ')

  _closeTag: (event) ->
    return if @extension not in @enabledFileExtensions

    {text, range} = event
    if text is '\n'
      @_addIndent event.range
      return

    return if text isnt '>' and text isnt '/'

    line = @currentEditor.buffer.getLines()[range.end.row]
    strBefore = line.substr 0, range.start.column
    strAfter = line.substr range.end.column
    previousTagIndex = strBefore.lastIndexOf('<')

    if previousTagIndex < 0
      return

    tagName = strBefore.match(/^.*\<([a-zA-Z-_.]+)[^>]*?/)?[1]
    if !tagName then return

    if text is '>'
      if strBefore[strBefore.length - 1] is '/'
        return

      # dont close if its already close by />
      if strBefore.substr(strBefore.length - 2) is "/>"
        return

      # dont close if already closed by </tagName>
      if strAfter.indexOf("</#{tagName}>") isnt -1
        return

      @currentEditor.insertText "</#{tagName}>"
      @currentEditor.moveLeft tagName.length + 3
    else if text is '/'
      if strAfter[0] is '>'
        closingTagIndex = strAfter.indexOf("</#{tagName}>")
        if closingTagIndex isnt -1
          @currentEditor.moveToEndOfLine()
          @currentEditor.selectLeft("</#{tagName}>".length)
          @currentEditor.delete()
          @currentEditor.moveLeft 2
      else
        @currentEditor.insertText '>'

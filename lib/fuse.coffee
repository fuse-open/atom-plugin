SelectionChangedNotifier = require './selectionChangedNotifier'
Daemon = require './daemon'
UXProvider = require './uxProvider'
{ErrorListView, ErrorListModel} = require './errorListView'
{SubscribeRequest} = require './messages'
process = require 'process'
{CompositeDisposable, Disposable, Point} = require 'atom'

module.exports = Fuse =
  config:
    fuseCommand:
      type: 'string'
      default: 'fuse'
      description: 'Set absolute path/name of fuse executable.'

  subscriptions: null
  daemon: null

  activate: (state) ->
    console.log('fuse: Starting fuse.')
    if process.platform == 'darwin'
      process.env["PATH"] += ':/usr/local/bin'

    @subscriptions = new CompositeDisposable
    @initializeViewProviders state

    @daemon = new Daemon(atom.config.get('fuse.fuseCommand'))
    @subscriptions.add @daemon
    @subscriptions.add new SelectionChangedNotifier(@daemon)

    errorlistModel = new ErrorListModel
    @errorList = atom.views.getView(errorlistModel)
    atom.workspace.addBottomPanel(item: @errorList, visibility: true, priority: 100)

    @uxProvider = new UXProvider @daemon

    buildId = 0
    @daemon.observeBroadcastedEvents 'Fuse.BuildStarted', false, (msg) ->
      errorlistModel.clear()
      if msg.data.BuildType == 'LoadMarkup'
        buildId = msg.data.BuildId

    @daemon.observeBroadcastedEvents 'Fuse.BuildIssueDetected', false, (msg) ->
      if msg.data.BuildId == buildId
        position = msg.data.StartPosition ? {Line: 0, Character: 0}
        position = new Point(position.Line - 1, position.Character - 1)
        errorlistModel.report type: msg.data.IssueType, description: msg.data.Message, file: msg.data.Path, position: position

  initializeViewProviders: (state) ->
    atom.views.addViewProvider ErrorListModel, (errorList) ->
      errorListView = new ErrorListView state.errorListViewState, errorList
      return errorListView

  getProvider: ->
    #@uxProvider

  deactivate: ->
    @subscriptions.dispose()
    @errorList.destroy()

  serialize: ->
    errorListViewState: @errorList.serialize()

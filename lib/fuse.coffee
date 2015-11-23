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

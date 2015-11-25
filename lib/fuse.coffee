SelectionChangedNotifier = require './selectionChangedNotifier'
Daemon = require './daemon'
UXProvider = require './uxProvider'
BuildObserver = require './buildObserver'
{ErrorListView, ErrorListModel} = require './errorListView'
{SubscribeRequest} = require './messages'
process = require 'process'
{CompositeDisposable, Disposable, Point} = require 'atom'
FuseBottomPanel = require './fuseBottomPanel'
{OutputView, OutputModel} = require './outputView'
apd = require('atom-package-dependencies');
apd.install()

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
    @daemon = new Daemon(atom.config.get('fuse.fuseCommand'))
    @subscriptions.add @daemon
    @subscriptions.add new SelectionChangedNotifier @daemon

    @fuseBottomPanel = new FuseBottomPanel state.fuseBottomPanel
    atom.workspace.addBottomPanel(item: @fuseBottomPanel, visibility: true, priority: 100)

    @subscriptions.add atom.commands.add 'atom-workspace', 'fuse:panel': =>
      @fuseBottomPanel.toggle()

    buildObserver = new BuildObserver @daemon.observeBroadcastedEvents
    @subscriptions.add buildObserver

    errorlistModel = new ErrorListModel buildObserver
    outputModel = new OutputModel

    @fuseBottomPanel.addTab 'Error List', ->
      new ErrorListView errorlistModel
    @fuseBottomPanel.addTab 'Output', ->
      new OutputView outputModel

    @uxProvider = new UXProvider @daemon

  getProvider: ->
    #@uxProvider

  deactivate: ->
    @subscriptions?.dispose()
    @fuseBottomPanel?.destroy()

  serialize: ->
    fuseBottomPanel: @fuseBottomPanel?.serialize()

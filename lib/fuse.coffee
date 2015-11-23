SelectionChangedNotifier = require './selectionChangedNotifier'
Daemon = require './daemon'
UXProvider = require './uxProvider'
ErrorListView = require './errorListView'
{SubscribeRequest} = require './messages'
process = require 'process'
{CompositeDisposable, Disposable} = require 'atom'

module.exports = Fuse =
  config:
    fuseCommand:
      type: 'string'
      default: 'fuse'
      description: 'Set absolute path/name of fuse executable.'

  subscriptions: null
  daemon: null

  activate: (state) ->
    console.log("Starting fuse.")
    if process.platform == 'darwin'
      process.env["PATH"] += ':/usr/local/bin'

    @daemon = new Daemon(atom.config.get("fuse.fuseCommand"))
    @errorList = new ErrorListView(state.errorListViewState)
    @errorList.show()
    atom.workspace.addBottomPanel(item: @errorList, priority: 100)
    @uxProvider = new UXProvider @daemon

    @subscriptions = new CompositeDisposable
    @subscriptions.add(new SelectionChangedNotifier(@daemon))

  getProvider: ->
    #@uxProvider

  deactivate: ->
    @subscriptions.dispose()
    @daemon.dispose()
    @errorList.destroy()

  serialize: ->
    errorListViewState: @errorList.serialize()

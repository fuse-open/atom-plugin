SelectionChangedNotifier = require './selectionChangedNotifier'
Daemon = require './daemon'
{CompositeDisposable, Disposable} = require 'atom'

module.exports = Fuse =
  subscriptions: null
  daemon: null

  activate: (state) ->
    @daemon = new Daemon
    @subscriptions = new CompositeDisposable
    @subscriptions.add(new SelectionChangedNotifier(@daemon))

  deactivate: ->
    @subscriptions.dispose()
    @daemon.dispose()

  serialize: ->

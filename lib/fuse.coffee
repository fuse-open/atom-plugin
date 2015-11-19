SelectionChangedNotifier = require './selectionChangedNotifier'
Daemon = require './daemon'
{SubscribeRequest} = require './messages'
process = require 'process'
{CompositeDisposable, Disposable} = require 'atom'

module.exports = Fuse =
  config:
    fuseCommand:
      type: "string"
      default: "fuse"
      description: "Set absolute path/name of fuse executable."

  subscriptions: null
  daemon: null

  activate: (state) ->
    if process.platform == 'darwin'
      process.env["PATH"] += ":/usr/local/bin"

    @daemon = new Daemon(atom.config.get("fuse.fuseCommand"))

    @daemon.request(
      new SubscribeRequest(
        filter: ".*",
        replay: false,
        subscriptionId: 0
      ),
      (response) =>
        console.log(response.status)
    )

    @subscriptions = new CompositeDisposable
    @subscriptions.add(new SelectionChangedNotifier(@daemon))

  deactivate: ->
    @subscriptions.dispose()
    @daemon.dispose()

  serialize: ->

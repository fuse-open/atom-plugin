{Emitter, CompositeDisposable, Disposable} = require 'atom'

module.exports =
class BuildObserver extends Disposable
  constructor: (observeBroadcastedEvents) ->
    super @dispose
    @emitter = new Emitter

    @subscriptions = new CompositeDisposable
    @subscriptions.add observeBroadcastedEvents 'Fuse.BuildStarted', false, @onBuildStarted
    @subscriptions.add observeBroadcastedEvents 'Fuse.BuildIssueDetected', false, @onBuildIssueDetected

  observeOnBuildStarted: (callback) ->
    @emitter.on 'build-started', callback

  observeOnBuildIssues: (callback) ->
    @emitter.on 'build-issue-detected', callback

  onBuildStarted: (msg) =>
    @emitter.emit 'build-started', msg.data

  onBuildIssueDetected: (msg) =>
    @emitter.emit 'build-issue-detected', msg.data

  dispose: ->
    @subscriptions.dispose()

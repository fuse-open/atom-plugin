{Emitter, CompositeDisposable, Disposable} = require 'atom'

module.exports =
class BuildObserver extends Disposable
  constructor: (observeBroadcastedEvents) ->
    super @dispose
    @emitter = new Emitter

    @subscriptions = new CompositeDisposable
    @subscriptions.add observeBroadcastedEvents 'Fuse.BuildStarted', false, @onBuildStarted
    @subscriptions.add observeBroadcastedEvents 'Fuse.BuildIssueDetected', false, @onBuildIssueDetected
    @subscriptions.add observeBroadcastedEvents 'Fuse.BuildLogged', false, @onBuildLogged

  observeOnBuildStarted: (callback) ->
    @emitter.on 'build-started', callback

  observeOnBuildIssues: (callback) ->
    @emitter.on 'build-issue-detected', callback

  observeOnBuildLogged: (callback) ->
    @emitter.on 'build-logged', callback

  onBuildStarted: (msg) =>
    @emitter.emit 'build-started', msg.data

  onBuildIssueDetected: (msg) =>
    @emitter.emit 'build-issue-detected', msg.data

  onBuildLogged: (msg) =>
    @emitter.emit 'build-logged', msg.data

  dispose: ->
    @subscriptions.dispose()

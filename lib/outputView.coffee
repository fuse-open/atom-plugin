{$, $$, View} = require 'atom-space-pen-views'
{Emitter, Disposable, CompositeDisposable} = require 'atom'

module.exports =
LogEvent:
  class LogEvent
    constructor: (args) ->
      {@message} = args
OutputModel:
  class OutputModel extends Disposable
    logEvents: []

    constructor: (buildObserver) ->
      super @dispose
      @emitter = new Emitter
      @subscriptions = new CompositeDisposable

      lastId = -1
      @subscriptions.add buildObserver.observeOnBuildStarted (data) =>
        if lastId != data.BuildId
          lastId = data.BuildId
          @clear()

      @subscriptions.add buildObserver.observeOnBuildLogged (data) =>
        if lastId != data.BuildId
          return
        @log new LogEvent message: data.Message ? ""

    observeLogEvents: (callback) ->
      callback(logEvent) for logEvent in @logEvents
      return @emitter.on 'new-log-event', callback

    observeOnClear: (callback) ->
      return @emitter.on 'clear', callback

    log: (logEvent) ->
      @logEvents.push logEvent
      @emitter.emit 'new-log-event', logEvent

    clear: ->
      @logEvents = []
      @emitter.emit 'clear'

    dispose: ->
      @buildLogEventSub.dispose()
      @subscriptions.dispose()

OutputView:
  class OutputView extends View
    @content: ->
      @div =>
        @pre class: 'output-panel native-key-bindings', outlet: 'output', tabindex: -1

    initialize: (model) ->
      @logEventSub = model.observeLogEvents (logEvent) =>
        @log(logEvent.message)
      @clearSub = model.observeOnClear =>
        @clear()

    clear: ->
      @output.empty()

    log: (message) ->
      if typeof message == 'string'
        @output.append $$ ->
          @p message
      else
        @output.append message

    destroy: ->
      logEventSub?.dispose()

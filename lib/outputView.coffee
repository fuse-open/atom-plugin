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

      if not @scrollProvider?
        return

      atBottom = (@scrollProvider.scrollTop() + @scrollProvider.innerHeight() + 30 > @scrollProvider[0].scrollHeight)
      if atBottom
        @scrollProvider.scrollTop(@scrollProvider[0].scrollHeight)

    setScrollProvider: (@scrollProvider) ->
      @scrollProvider.scrollTop(@scrollProvider[0].scrollHeight)

    destroy: ->
      @logEventSub?.dispose()
      @clearSub?.dispose()

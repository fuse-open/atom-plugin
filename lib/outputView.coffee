{$, $$, View} = require 'atom-space-pen-views'
{Emitter} = require 'atom'

module.exports =
OutputModel:
  class OutputModel
    logEvents: []

    constructor: ->
      @emitter = new Emitter
      for i in [0..100]
        @log message: "Message " + i

    observeLogEvents: (callback) ->
      callback(logEvent) for logEvent in @logEvents
      return @emitter.on 'new-log-event', callback

    log: (logEvent) ->
      @logEvents.push logEvent
      @emitter.emit 'new-log-event', logEvent

OutputView:
  class OutputView extends View
    @content: ->
      @div =>
        @pre class: 'native-key-bindings', outlet: 'output', tabindex: -1

    initialize: (model) ->
      @logEventSub = model.observeLogEvents (logEvent) =>
        @log(logEvent.message)

    log: (message) ->
      if typeof message == 'string'
        @output.append $$ ->
          @p message
      else
        @output.append message

    destroy: ->
      logEventSub?.dispose()

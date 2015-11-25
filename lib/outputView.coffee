{$, $$, View} = require 'atom-space-pen-views'

module.exports =
class OutputView extends View
  @content: ->
    @div =>
      @pre class: 'native-key-bindings', outlet: 'output', tabindex: -1

  initialize: ->
    for i in [0..100]
      @log("Message " + i, "Error")

  log: (message, level) ->
    if typeof message == 'string'
      @output.append $$ ->
        @p message
    else
      @output.append message

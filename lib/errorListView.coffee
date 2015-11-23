{$, $$, View, TextEditorView, ScrollView} = require 'atom-space-pen-views'

module.exports =
class ErrorListView extends View
  @content: ->
    @div class: 'fuse view-resizer panel', =>
      @div class: 'view-resize-handle', outlet: 'resizeHandle'
      @div class: 'panel-heading', dblclick: 'toggle', outlet: 'heading', 'Fuse - Error List', =>
        @button class: 'btn pull-right', click: 'clear', 'Clear'
      @div class: 'panel-body view-scroller', outlet: 'body', =>
        @table class: 'error-list-table native-key-bindings', tabindex: -1, =>
          @thead =>
            @tr =>
              @th 'Type'
              @th 'Description'
              @th 'File'
              @th 'Line : Column'
          @tbody outlet: 'errorTableBody'

  initialize: (serializedState) ->
    @body.height serializedState?.height
    @handleEvents()
    for i in [0...1000]
      @log("Row " + i, "foo")

  clear: ->
    @errorTableBody.empty()

  log: (message, level) ->
    if typeof message == 'string'
      @errorTableBody.append "<tr><td>#{message}</td><td>Column 2: #{message}</td></tr>"
    else
      @errorTableBody.append message

    @show()

  handleEvents: ->
    @on 'mousedown', '.view-resize-handle', (e) => @resizeStarted(e)

  resizeStarted: =>
    $(document).on('mousemove', @resizeView)
    $(document).on('mouseup', @resizeStopped)

  resizeStopped: =>
    $(document).off('mousemove', @resizeView)
    $(document).off('mouseup', @resizeStopped)

  resizeView: ({which, pageY}) =>
    return @resizeStopped() unless which is 1
    @body.height($(document.body).height() - pageY - @heading.outerHeight())

  serialize: ->
    height: @body.height()

{$, $$, View, TextEditorView, ScrollView} = require 'atom-space-pen-views'
{Point, Emitter} = require 'atom'

module.exports =
ErrorListModel:
  class ErrorListModel
    buildEvents: []

    constructor: ->
      @emitter = new Emitter

    observeBuildEvents: (callback) ->
      callback(buildEvent) for buildEvent in @buildEvents
      @emitter.on 'new-build-event', callback

    report: (args) ->
      @buildEvents.push args
      @emitter.emit 'new-build-event', args

ErrorListView:
  class ErrorListView extends View
    @content: ->
      @div class: 'fuse view-resizer panel', =>
        @div class: 'view-resize-handle', outlet: 'resizeHandle'
        @div class: 'panel-heading', dblclick: 'toggle', outlet: 'heading', 'Fuse - Error List'
        @div class: 'panel-body view-scroller', outlet: 'body', =>
          @table class: 'error-list-table native-key-bindings', tabindex: -1, =>
            @thead =>
              @tr =>
                @th 'Type'
                @th 'Description'
                @th 'File'
                @th 'Line : Column'
            @tbody outlet: 'errorTableBody'

    initialize: (serializedState, model) ->
      @body.height serializedState?.height
      @handleEvents()

      @buildEventsSub = model?.observeBuildEvents (evt) =>
        @report(evt.type, evt.description, evt.file, evt.position)

    destroy: =>
      @buildEventsSub?.dispose()

    clear: ->
      @errorTableBody.empty()

    report: (type, message, file, position) ->
      pos = {line: position.row + 1, character: position.column}
      if typeof message == 'string'
        @errorTableBody.append "<tr><td>#{type}</td><td>#{message}</td><td>#{file}</td><td>#{pos.line} : #{pos.character}</td></tr>"
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

{$, $$, View, TextEditorView, ScrollView} = require 'atom-space-pen-views'
{Point, Emitter} = require 'atom'

module.exports =
ErrorListModel:
  class ErrorListModel
    buildEvents: []

    constructor: (@buildObserver) ->
      @emitter = new Emitter

      lastId = -1
      buildObserver.observeOnBuildStarted (data) =>
        if lastId != data.BuildId
          lastId = data.BuildId
          @clear()

      buildObserver.observeOnBuildIssues (data) =>
        if lastId != data.BuildId
          return
        position = data.StartPosition ? {Line: 0, Character: 0}
        position = new Point(position.Line - 1, position.Character - 1)
        @report({
          type: data.IssueType,
          description: data.Message,
          file: data.Path,
          position: position
        })

    observeBuildEvents: (callback) ->
      callback(buildEvent) for buildEvent in @buildEvents
      return @emitter.on 'new-build-event', callback

    report: (args) ->
      @buildEvents.push args
      @emitter.emit 'new-build-event', args

    observeOnClear: (callback) ->
      return @emitter.on 'clear-build-events', callback

    openEditorForPath: (file, position) ->
      atom.workspace.open(file, initialLine: position.row, initialColumn: position.column)

    clear: ->
      @buildEvents = []
      @emitter.emit 'clear-build-events'

ErrorListView:
  class ErrorListView extends View
    @content: ->
      @table class: 'error-list-table native-key-bindings', tabindex: -1, =>
        @thead =>
          @tr =>
            @th 'Type'
            @th 'Description'
            @th 'File'
            @th 'Line : Column'
        @tbody outlet: 'errorTableBody'

    initialize: (@model) ->
      @handleEvents()

      @buildEventsSub = @model?.observeBuildEvents (evt) =>
        @report(evt.type, evt.description, evt.file, evt.position)

      @clearSub = @model?.observeOnClear =>
        @clear()

    destroy: ->
      @buildEventsSub?.dispose()
      @clearSub?.dispose()

    clear: ->
      @errorTableBody.empty()

    report: (type, message, file, position) ->
      pos = {line: position.row + 1, character: position.column + 1}
      if typeof message == 'string'
        @errorTableBody.append "<tr><td>#{type}</td><td>#{message}</td><td>#{file}</td><td>#{pos.line} : #{pos.character}</td></tr>"
      else
        @errorTableBody.append message

      @show()

    handleEvents: ->
      @on 'dblclick', '.error-list-table tr', @errorDoubleClicked

    errorDoubleClicked: (e) =>
      target = e.currentTarget
      path = target.cells[2].outerText
      lineCol = target.cells[3].outerText.split(' : ')
      @model.openEditorForPath path, new Point(parseInt(lineCol[0]) - 1, parseInt(lineCol[1]) - 1)

{$, $$, View} = require 'atom-space-pen-views'

module.exports =
class FuseBottomPanel extends View
  @content: ->
    @div class: 'fuse view-resizer panel', =>
      @div class: 'view-resize-handle', outlet: 'resizeHandle'
      @div class: 'panel-heading', dblclick: 'toggle', outlet: 'heading', 'Fuse'
      @div class: 'panel-body view-scroller', outlet: 'body'

  initialize: (serializedState) ->
    @body.height serializedState?.height
    @handleEvents()

  handleEvents: ->
    @on 'mousedown', '.view-resize-handle', @resizeStarted

  setInnerElement: (header, element) ->
    @heading.empty().append('Fuse - ' + header)
    @body.empty().append(element)

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

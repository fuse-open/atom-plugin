{$, $$, View} = require 'atom-space-pen-views'

module.exports =
class FuseBottomPanel extends View
  @content: ->
    @div class: 'fuse view-resizer panel', =>
      @div class: 'view-resize-handle', outlet: 'resizeHandle'
      @div class: 'panel-heading', dblclick: 'toggle', outlet: 'heading', =>
        @span id: 'headText', 'Fuse'
      @div class: 'panel-body view-scroller', outlet: 'body'

  initialize: (serializedState) ->
    @numTabs = 0
    @body.height serializedState?.height
    @handleEvents()

  handleEvents: ->
    @on 'mousedown', '.view-resize-handle', @resizeStarted

  addTab: (header, factory) ->
    id = header.replace(/\s+/g, '-')
    @heading.append $$ ->
      @button class: 'btn pull-right', id: id, header
    @on 'click', "\##{id}", (args) => @setInnerElement(header, factory())

    if @numTabs == 0
      @setInnerElement(header, factory())

  setInnerElement: (header, element) ->
    $("#headText").replaceWith('Fuse - ' + header)
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

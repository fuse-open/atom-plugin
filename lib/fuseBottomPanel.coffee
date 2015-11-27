{$, $$, View} = require 'atom-space-pen-views'

module.exports =
class FuseBottomPanel extends View
  @content: ->
    @div class: 'fuse view-resizer panel', =>
      @div class: 'view-resize-handle', outlet: 'resizeHandle'
      @div class: 'fuse-panel-heading panel-heading', dblclick: 'toggle', outlet: 'heading', =>
        @div class: 'fuse-img'
        @span class: 'panel-head-text', outlet: 'headText', 'Fuse'
      @div class: 'panel-body view-scroller', outlet: 'body'

  innerElement: null

  initialize: (serializedState) ->
    @numTabs = 0
    @body.height serializedState?.height
    @handleEvents()

  handleEvents: ->
    @on 'mousedown', '.view-resize-handle', @resizeStarted

  addTab: (header, factory) ->
    id = header.replace(/\s+/g, '-')
    @heading.prepend $$ ->
      @button class: 'fuse-button btn pull-right', id: id, header
    @on 'click', "\##{id}", (args) => @setInnerElement(header, factory())

    if @numTabs == 0
      @setInnerElement(header, factory())
      ++@numTabs

  setInnerElement: (header, element) ->
    @headText.text(header)
    @body.empty().append(element)

    @innerElement?.destroy?()
    @innerElement = element
    @innerElement.setScrollProvider? @body

  resizeStarted: =>
    $(document).on('mousemove', @resizeView)
    $(document).on('mouseup', @resizeStopped)

  resizeStopped: =>
    $(document).off('mousemove', @resizeView)
    $(document).off('mouseup', @resizeStopped)

  resizeView: ({which, pageY}) =>
    return @resizeStopped() unless which is 1
    @body.height($(document.body).height() - pageY - @heading.outerHeight())

  destroy: ->
    @innerElement?.destroy?()

  serialize: ->
    height: @body.height()

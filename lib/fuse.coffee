FuseView = require './fuse-view'
{CompositeDisposable} = require 'atom'

module.exports = Fuse =
  fuseView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @fuseView = new FuseView(state.fuseViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @fuseView.getElement(), visible: false)

  deactivate: ->
    @modalPanel.destroy()
    @fuseView.destroy()

  serialize: ->
    fuseViewState: @fuseView.serialize()

  toggle: ->
    console.log 'Fuse was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()

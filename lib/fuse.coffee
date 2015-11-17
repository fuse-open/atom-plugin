FuseView = require './fuse-view'
{CompositeDisposable} = require 'atom'

module.exports = Fuse =
  fuseView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @fuseView = new FuseView(state.fuseViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @fuseView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'fuse:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @fuseView.destroy()

  serialize: ->
    fuseViewState: @fuseView.serialize()

  toggle: ->
    console.log 'Fuse was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()

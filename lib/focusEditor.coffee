{Response} = require './messageTypes'

module.exports =
FocusEditorListener:
  class FocusEditorListener
    constructor: (registerRequestListener) ->
      registerRequestListener 'FocusEditor', @onFocusEditorRequest

    onFocusEditorRequest: (request, responder) ->
      args = request.arguments
      console.log "fuse: Bringing focus to " + args.File + "(" + args.Line + "," + args.Column + ")"
      if atom.project.contains args.Project
        atom.workspace.open args.File, { initialLine: args.Line - 1, initialColumn: args.Column - 1, searchAllPanes: true }
        atom.focus()
        responder new Response(request.id, "Success", [], {})
      else
        responder new Response(request.id, "Unhandled", [], {})


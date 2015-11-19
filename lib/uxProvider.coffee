{GetCodeSuggestionsRequest} = require './messages'
{Point} = require 'atom'

module.exports =
class UXProvider
  selector: '.ux'

  inclusionPriority: 1
  excludeLowerPriority: true

  filterSuggestions: true

  constructor: (@daemon) ->

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix, activatedManually}) ->
    new Promise (resolve) =>
      path = editor.getPath()
      text = editor.getText()
      @daemon.request(
        new GetCodeSuggestionsRequest(
          text: text,
          path: path,
          syntaxType: 'ux'
          caretPosition: bufferPosition
        ),
        (response) =>
          if response.status != "Success"
            resolve([])
            return

          suggestions = response.result.CodeSuggestions
          completions = []
          for suggestion in suggestions
            completions.push {text: suggestion.Suggestion}

          resolve(completions)
      )

  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->

  dispose: ->

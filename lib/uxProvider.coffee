{GetCodeSuggestionsRequest} = require './messages'

module.exports =
class UXProvider
  selector: '.text.ux'
  disableForSelector: '.text.ux .comment'

  inclusionPriority: 1
  excludeLowerPriority: true

  filterSuggestions: true

  constructor: (@daemon) ->

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix, activatedManually}) ->
    # Check if we are around a '/>'
    scopes = scopeDescriptor.scopes
    if scopes[scopes.length - 1] == 'text.ux'
      return []

    new Promise (resolve) =>
      path = editor.getPath()
      text = editor.getText().replace(/\r/gm, '')
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
            completions.push @buildSuggestion(suggestion)

          resolve(completions)
      )

  buildSuggestion: (suggestion) ->
    if suggestion.Type == 'Class'
      return {
        text: suggestion.Suggestion,
        type: 'tag'
      }
    else if suggestion.Type == 'Property'
      return {
        displayText: suggestion.Suggestion,
        snippet: "#{suggestion.Suggestion}=\"$1\"$0"
        type: 'attribute'
      }
    else
      return {
        text: suggestion.Suggestion,
        type: 'value'
      }

  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->

  dispose: ->

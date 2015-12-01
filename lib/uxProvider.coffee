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
    if scopes.indexOf('punctuation.definition.tag.xml') isnt -1 or
        scopes[scopes.length - 1] == 'text.ux'
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
            if suggestion.Type == 'Class'
              completions.push {
                text: suggestion.Suggestion,
                type: 'tag'
              }
            else if suggestion.Type == 'Property'
              completions.push {
                displayText: suggestion.Suggestion,
                snippet: "#{suggestion.Suggestion}=\"$1\"$0"
                type: 'attribute'
              }
            else
              completions.push {
                text: suggestion.Suggestion,
                type: 'value'
              }

          resolve(completions)
      )

  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->

  dispose: ->

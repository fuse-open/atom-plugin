{GetCodeSuggestionsRequest} = require './messages'

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
              type = 'class'
            if suggestion.Type == 'Property'
              type = 'property'

            completions.push {text: suggestion.Suggestion, type: type}

          resolve(completions)
      )

  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->

  dispose: ->

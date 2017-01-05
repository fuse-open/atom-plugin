{GetCodeSuggestionsRequest} = require './messages'
{Range} = require 'atom'

module.exports =
class UXProvider
  selector: '.text.xml.ux'
  disableForSelector: '.text.xml.ux .comment'

  inclusionPriority: 1
  excludeLowerPriority: true

  filterSuggestions: true

  constructor: (@daemon) ->

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix, activatedManually}) ->
    scopes = scopeDescriptor.scopes

    # Check if we are around a '/>'
    # Or in a inner element area
    nextTwoChars = editor.getTextInBufferRange(
      new Range(bufferPosition, bufferPosition.translate([0,2])))
    isEndOfScope = scopes.indexOf('punctuation.definition.tag.xml') isnt -1 and nextTwoChars != "/>"

    if isEndOfScope or scopes[scopes.length - 1] == 'text.ux'
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

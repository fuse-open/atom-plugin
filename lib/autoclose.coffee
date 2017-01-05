module.exports =
class AutoCloser
  currentEditor: null
  action: null
  extension: ''
  autocloseEnabled: true

  constructor: () ->
    atom.config.observe 'fuse.autocloseEnabled', (value) =>
      @autocloseEnabled = value

    @currentEditor = atom.workspace.getActiveTextEditor()
    if @currentEditor
      @action = @currentEditor.onDidInsertText (event) =>
        @closeTag(event)
    @getFileExtension()
    atom.workspace.onDidChangeActivePaneItem (paneItem) =>
      @paneItemChanged(paneItem)

  deactivate: () ->
    if @action then @action.disposalAction()

  getFileExtension: ->
    filename = @currentEditor?.getFileName?()
    @extension = filename?.substr filename?.lastIndexOf('.') + 1

  paneItemChanged: (paneItem) ->
    if !paneItem then return

    if @action then @action.disposalAction()
    @currentEditor = paneItem
    @getFileExtension()
    if @currentEditor.onDidInsertText
      @action = @currentEditor.onDidInsertText (event) =>
        @closeTag(event)

  addIntent: (range) ->
    {start, end} = range
    buffer = @currentEditor.buffer
    lineBefore = buffer.getLines()[start.row]
    lineAfter = buffer.getLines()[end.row]
    content = lineBefore.substr(lineBefore.lastIndexOf('<')) + '\n' + lineAfter
    regex = ///
              ^.*\<([a-zA-Z-_]+)(\s.+)?\>
              \n
              \s*\<\/\1\>.*
            ///

    if regex.test content
      @currentEditor.insertNewlineAbove()
      @currentEditor.insertText('  ')

  closeTag: (event) ->
    return if not @autocloseEnabled
    return if @extension isnt "ux"

    {text, range} = event
    if text is '\n'
      @addIntent event.range
      return

    return if text isnt '>' and text isnt '/'

    line = @currentEditor.buffer.getLines()[range.end.row]
    strBefore = line.substr 0, range.start.column
    strAfter = line.substr range.end.column
    previousTagIndex = strBefore.lastIndexOf('<')

    if previousTagIndex < 0
      return

    tagName = strBefore.match(/^.*\<([a-zA-Z-_.]+)[^>]*?/)?[1]
    if !tagName then return

    if text is '>'
      if strBefore[strBefore.length - 1] is '/'
        return

      # dont close if its already close by />
      if strBefore.substr(strBefore.length - 2) is "/>"
        return

      # dont close if already closed by </tagName>
      if strAfter.indexOf("</#{tagName}>") isnt -1
        return

      @currentEditor.insertText "</#{tagName}>"
      @currentEditor.moveLeft tagName.length + 3
    else if text is '/'
      if strAfter[0] is '>'
        closingTagIndex = strAfter.indexOf("</#{tagName}>")
        if closingTagIndex isnt -1
          @currentEditor.moveToEndOfLine()
          @currentEditor.selectLeft("</#{tagName}>".length)
          @currentEditor.delete()
          @currentEditor.moveLeft 2
      else
        @currentEditor.insertText '>'

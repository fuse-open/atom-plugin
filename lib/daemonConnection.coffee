{Disposable} = require 'atom'
{spawn} = require 'child_process'
{Event, Message} = require './messageTypes'

module.exports =
  class DaemonConnection extends Disposable
    fuseClient: null

    constructor: (daemonCommand, @msgReceivedCallback) ->
      super(@dispose)
      @fuseClient = spawn(daemonCommand, ['daemon-client', 'Atom Plugin'])

      buffer = new Buffer(0)
      @fuseClient.stdout.on('data', (data) =>
        latestBuf = Buffer.concat([buffer, data])
        buffer = @parseMsgFromBuffer(latestBuf, @msgReceivedCallback)
      )

      @fuseClient.stderr.on('data', (data) ->
        console.log('fuse: ' + data.toString('utf-8'))
      )

      @fuseClient.on('close', (code) ->
        console.log('fuse: daemon client closed with code ' + code)
      )

    parseMsgFromBuffer: (buffer, msgCallback) =>
      start = 0
      while start < buffer.length
        endOfMsgType = buffer.indexOf('\n', start)
        if(endOfMsgType < 0)
          break # Incomplete or corrupt data

        startOfLength = endOfMsgType + 1
        endOfLength = buffer.indexOf('\n', startOfLength)
        if(endOfLength < 0)
          break # Incomplete or corrupt data

        msgType = buffer.toString('utf-8', start, endOfMsgType)
        length = parseInt(buffer.toString('utf-8', startOfLength, endOfLength))
        if length == NaN
          console.log('fuse: Corrupt length in data received from Fuse.')
          # Try recover by starting from the beginning
          start = endOfLength + 1
          continue

        startOfData = endOfLength + 1
        endOfData = startOfData + length
        if buffer.length < endOfData
          break # Incomplete data

        jsonData = buffer.toString('utf-8', startOfData, endOfData)
        msgCallback Message.deserialize(msgType, jsonData)
        start = endOfData

      return buffer.slice(start, buffer.length)

    send: (msgType, serializedMsg) =>
      # Pack the message to be compatible with Fuse Protocol.
      # As:
      # ```
      # MessageType (msgType)
      # Length (length)
      # JSON(serializedMsg)
      # ```
      # For example:
      # ```
      # Event
      # 50
      # {
      #   "Name": "Test",
      #   "Data":
      #   {
      #     "Foo": "Bar"
      #   }
      # }
      # ```
      length = Buffer.byteLength(serializedMsg, 'utf-8')
      packedMsg = msgType + '\n' + length + '\n' + serializedMsg
      @fuseClient.stdin.write packedMsg

    dispose: =>

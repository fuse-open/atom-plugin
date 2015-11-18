{Disposable} = require 'atom'
{spawn} = require 'child_process'

module.exports =
  class DaemonConnection extends Disposable
    fuseClient: null

    constructor: (daemonCommand) ->
      super(@dispose)
      @fuseClient = spawn(daemonCommand, ['daemon-client', 'Atom Plugin'])

      @fuseClient.stdout.on('data', (data) ->
        console.log('stdout: ' + data)
      )

      @fuseClient.stderr.on('data', (data) ->
        console.log(data.toString('utf-8'))
      )

      @fuseClient.on('close', (code) ->
        console.log('child process exited with code ' + code)
      )

    send: (message) =>
      serializedMsg = message.serialize()
      length = Buffer.byteLength(serializedMsg, 'utf-8')
      finalMsg = message.messageType + "\n" + length + "\n" + serializedMsg
      @fuseClient.stdin.write(finalMsg)

    dispose: =>

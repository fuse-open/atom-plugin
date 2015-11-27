{Disposable} = require 'atom'

module.exports =
class Preview extends Disposable
  constructor: (fuseLauncher, target, path) ->
    super @dispose
    @fuseProc = fuseLauncher.run ['preview', '-t=' + target, '--name=' + 'AtomEditor', path]

  @run: (fuseLauncher, target, path) ->
    return new Preview(fuseLauncher, target, path)

  observeOutput: (callback) ->
    @fuseProc.stdout.on 'data', (data) ->
      callback data.toString('utf-8').replace('\xa0','\x20')

  observeError: (callback) ->
    @fuseProc.stderr.on 'data', (data) ->
      callback data.toString('utf-8').replace('\xa0','\x20')

  observeKill: (callback) ->
    @fuseProc.on 'close', (code) =>
      callback code

  dispose: ->
    @fuseProc.kill()

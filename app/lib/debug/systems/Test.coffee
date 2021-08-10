System = require 'lib/world/system'

module.exports = class Test extends System
  constructor: (world, config) ->
    super world, config
    @idlers = @addRegistry (thang) -> thang.exists and thang.acts and thang.moves and thang.action is 'idle'

  update: ->
    # We return a simple numeric hash that will combine to a frame hash
    # help us determine whether this frame has changed in resimulations.
    hash = 0
    for thang in @idlers
      hash += thang.pos.x += 0.5 - Math.random()
      hash += thang.pos.y += 0.5 - Math.random()
      thang.hasMoved = true
    return hash
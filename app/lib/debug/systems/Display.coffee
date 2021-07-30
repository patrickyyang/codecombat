System = require 'lib/world/system'

module.exports = class Display extends System
  constructor: (world, config) ->
    super world, config

  update: ->
    # We return a simple numeric hash that will combine to a frame hash
    # help us determine whether this frame has changed in resimulations.
    hash = 0
    return hash

  nextDrawsBoundsIndex: ->
    boundsDrawers = (t for t in @world.thangs when t.exists and t.drawsBounds)
    for i in [1 ... boundsDrawers.length]
      return i unless _.find boundsDrawers, {drawsBoundsIndex: i}
    boundsDrawers.length

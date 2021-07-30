System = require 'lib/world/system'

module.exports = class Effect extends System
  constructor: (world, config) ->
    super world, config
    @affected = @addRegistry (thang) -> thang.hasEffects and thang.effects.length

  update: ->
    affected = @affected.slice()  # avoid changing during iteration
    for thang in affected
      thang.updateEffects()
    return hash = 0
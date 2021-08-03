Component = require 'lib/world/component'

module.exports = class Hears extends Component
  @className: 'Hear'

  attach: (thang) ->
    super thang
    thang.hearingDelay = @hearingDelayMinimum + thang.world.rand.randf() * (1.5 * (@hearingDelayMaximum - @hearingDelayMinimum))

  hear: (speaker, message, data) ->

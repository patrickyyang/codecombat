Component = require 'lib/world/component'

module.exports = class CastsFling extends Component
  @className: 'CastsFling'

  constructor: (config) ->
    super config
    @_flingSpell = name: 'fling', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, mass: @mass
    delete @mass
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_flingSpell

  perform_fling: ->
    momentum = @target.pos.copy().subtract(@pos, true).normalize()
    momentum.z = 0.5
    momentum.multiply @spells.fling.mass, true
    @target.velocity.add momentum.divide(@target.mass, true), true
    @target.pos.z += 0.5  # Make sure it's off the ground so we don't get any friction
    @unhide?() if @hidden

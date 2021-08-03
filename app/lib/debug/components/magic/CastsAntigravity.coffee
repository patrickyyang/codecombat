Component = require 'lib/world/component'

module.exports = class CastsAntigravity extends Component
  @className: 'CastsAntigravity'

  constructor: (config) ->
    super config
    @_antigravitySpell = name: 'antigravity', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, radius: @radius, duration: @duration
    delete @radius
    delete @duration
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_antigravitySpell
    
  perform_antigravity: ->
    targetPos = @getTargetPos().copy()
    @world.getSystem("Movement").addGravityField {pos: targetPos, radius: @spells.antigravity.radius, duration: @spells.antigravity.duration, gravity: -9.81, attenuates: true, source: @}

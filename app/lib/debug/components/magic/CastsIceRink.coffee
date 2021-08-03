Component = require 'lib/world/component'

module.exports = class CastsIceRink extends Component
  @className: 'CastsIceRink'

  constructor: (config) ->
    super config
    @_iceRinkSpell = name: 'ice-rink', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, radius: @radius, duration: @duration
    delete @radius
    delete @duration
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_iceRinkSpell
    
  'perform_ice-rink': ->
    targetPos = @getTargetPos().copy()
    @world.getSystem("Movement").addFrictionField {pos: targetPos, radius: @spells['ice-rink'].radius, duration: @spells['ice-rink'].duration, friction: 0, source: @}

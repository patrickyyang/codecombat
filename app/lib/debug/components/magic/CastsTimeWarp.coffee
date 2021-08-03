Component = require 'lib/world/component'

module.exports = class CastsTimeWarp extends Component
  @className: 'CastsTimeWarp'

  constructor: (config) ->
    super config
    @_timeWarpSpell = name: 'time-warp', cooldown: @cooldown, specificCooldown: @specificCooldown, radius: @radius, factor: @factor, duration: @duration
    delete @factor
    delete @duration
    delete @cooldown
    delete @specificCooldown

  attach: (thang) ->
    super thang
    thang.addSpell @_timeWarpSpell
    
  castTimeWarp: ->
    @cast 'time-warp', @, 'castTimeWarp'

  'perform_time-warp': ->
    for target in @world.getSystem('Existence').extant when target.pos and @distance(target) < @spells['time-warp'].radius
      if target.hasEffects
        factor = @spells['time-warp'].factor
        name = if factor > 1 then 'haste' else 'slow'
        factor = Math.sqrt factor if target is @  # Don't slow the caster as much as everything else
        effects = [
          {name: name, duration: @spells['time-warp'].duration, reverts: true, factor: @spells['time-warp'].factor, targetProperty: 'maxSpeed'}
          {name: name, duration: @spells['time-warp'].duration, reverts: true, factor: @spells['time-warp'].factor, targetProperty: 'actionTimeFactor'}
        ]
        target.addEffect effect, @ for effect in effects
      else if target.velocity  # like missiles
        target.velocity.multiply @spells['time-warp'].factor, true
    args = [parseFloat(@pos.x.toFixed(2)), parseFloat(@pos.y.toFixed(2)), parseFloat(@spells['time-warp'].radius.toFixed(2)), '#55D3BA']
    @addCurrentEvent "aoe-#{JSON.stringify(args)}"

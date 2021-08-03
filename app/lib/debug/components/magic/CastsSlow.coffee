Component = require 'lib/world/component'

module.exports = class CastsSlow extends Component
  @className: 'CastsSlow'
  
  constructor: (config) ->
    super config
    @_slowSpell = name: 'slow', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, duration: @duration, factor: @factor
    delete @duration
    delete @factor
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_slowSpell
    
  castSlow: (target) ->
    @cast 'slow', target

  perform_slow: ->
    @target.effects = (e for e in @target.effects when e.name isnt 'slow')
    effects = [
      {name: 'slow', duration: @spells.slow.duration, reverts: true, setTo: true, targetProperty: 'isSlowed'}
      {name: 'slow', duration: @spells.slow.duration, reverts: true, factor: @spells.slow.factor, targetProperty: 'maxSpeed'}
      {name: 'slow', duration: @spells.slow.duration, reverts: true, factor: @spells.slow.factor, targetProperty: 'actionTimeFactor'}
    ]
    @target.addEffect effect, @ for effect in effects
    
  "getTarget_slow": ->
    return null unless thangs = @getEnemies?()
    nearest = null
    nearestDistanceSquared = Infinity
    rangeSquared = @spells.slow.range * @spells.slow.range
    for thang in thangs
      continue unless @canCast 'slow', thang
      distanceSquared = @distanceSquared thang
      if distanceSquared < nearestDistanceSquared and distanceSquared <= rangeSquared
        nearestDistanceSquared = distanceSquared
        nearest = thang
    return nearest

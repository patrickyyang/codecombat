Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

module.exports = class CastsGrow extends Component
  @className: 'CastsGrow'
  
  constructor: (config) ->
    super config
    @_growSpell = name: 'grow', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, duration: @duration, speedFactor: @speedFactor, healthFactor: @healthFactor
    delete @cooldown
    delete @specificCooldown
    delete @range
    delete @duration
    delete @healthFactor
    delete @speedFactor

  attach: (thang) ->
    super thang
    thang.addSpell @_growSpell
    
  castGrow: (target) ->
    @cast 'grow', target

  perform_grow: ->
    @target.effects = (e for e in @target.effects when e.name isnt 'grow')
    scaleFactor = @spells.grow.healthFactor * 1.5 / 2  # Don't grow visually quite as much as we do in mass
    effects = [
      {name: 'grow', duration: @spells.grow.duration, reverts: true, factor: @spells.grow.speedFactor, targetProperty: 'maxSpeed'}
      {name: 'grow', duration: @spells.grow.duration, reverts: true, factor: scaleFactor, targetProperty: 'scaleFactor'}
      {name: 'grow', duration: @spells.grow.duration, reverts: true, factor: scaleFactor * scaleFactor, targetProperty: 'mass'}
      {name: 'grow', duration: @spells.grow.duration, reverts: true, factor: @spells.grow.healthFactor, targetProperty: 'maxHealth'}
      {name: 'grow', duration: @spells.grow.duration, reverts: true, factor: @spells.grow.healthFactor, targetProperty: 'healthReplenishRate'}
      {name: 'grow', duration: @spells.grow.duration, revertsProportionally: true, factor: @spells.grow.healthFactor, targetProperty: 'health'}
    ]
    @target.addEffect effect, @ for effect in effects

  getTarget_grow: ->
    return null unless thangs = @getFriends?()
    #thangs = thangs.concat [@]
    nearest = null
    nearestDistanceSquared = Infinity
    rangeSquared = @spells.grow.range * @spells.grow.range
    for thang in thangs
      continue unless thang.health < thang.maxHealth and @canSee(thang) and @canCast 'grow', thang
      distanceSquared = @distanceSquared thang
      if distanceSquared < nearestDistanceSquared and distanceSquared <= rangeSquared
        nearestDistanceSquared = distanceSquared
        nearest = thang
    return nearest
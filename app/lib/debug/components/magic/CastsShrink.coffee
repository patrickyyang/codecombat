Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

module.exports = class CastsShrink extends Component
  @className: 'CastsShrink'
  
  constructor: (config) ->
    super config
    @_shrinkSpell = name: 'shrink', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, duration: @duration, speedFactor: @speedFactor, healthFactor: @healthFactor
    delete @duration
    delete @healthFactor
    delete @shrinkFactor
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_shrinkSpell
    
  castShrink: (target) ->
    @cast 'shrink', target

  perform_shrink: ->
    @target.effects = (e for e in @target.effects when e.name isnt 'shrink')
    effects = [
      {name: 'shrink', duration: @spells.shrink.duration, reverts: true, factor: @spells.shrink.speedFactor, targetProperty: 'maxSpeed'}
      {name: 'shrink', duration: @spells.shrink.duration, reverts: true, factor: 0.66, targetProperty: 'scaleFactor'}
      {name: 'shrink', duration: @spells.shrink.duration, reverts: true, factor: 0.66 * 0.66, targetProperty: 'mass'}
      {name: 'shrink', duration: @spells.shrink.duration, reverts: true, factor: @spells.shrink.healthFactor, targetProperty: 'maxHealth'}
      {name: 'shrink', duration: @spells.shrink.duration, reverts: true, factor: @spells.shrink.healthFactor, targetProperty: 'healthReplenishRate'}
      {name: 'shrink', duration: @spells.shrink.duration, revertsProportionally: true, factor: @spells.shrink.healthFactor, targetProperty: 'health'}
    ]
    if @target.team is @team and @world.getThangByID('Human Base') and @world.getThangByID('S Arrow Tower')
      effects.shift()  # Don't speed up teammates (nerf of munchkin rush on Brawlwood). We can remove when that's not so OP.
      @say? 'oh noes, team shrink speed nerfed!'
    @target.addEffect effect, @ for effect in effects
    
  getTarget_shrink: ->
    return null unless thangs = @getEnemies?()
    nearest = null
    nearestDistanceSquared = Infinity
    rangeSquared = @spells.shrink.range * @spells.shrink.range
    for thang in thangs
      continue unless thang.health < thang.maxHealth and @canCast 'shrink', thang
      distanceSquared = @distanceSquared thang
      if distanceSquared < nearestDistanceSquared and distanceSquared <= rangeSquared
        nearestDistanceSquared = distanceSquared
        nearest = thang
    return nearest   
Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

module.exports = class CastsPoisonCloud extends Component
  @className: "CastsPoisonCloud"

  constructor: (config) ->
    super config
    @_poisonCloudSpell = name: 'poison-cloud', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, damage: @damage, duration: @duration, repeatsEvery: @repeatsEvery, radius: @radius 
    @poisonCloudRadiusSquared = Math.pow @_poisonCloudSpell.radius, 2
    delete @cooldown
    delete @specificCooldown
    delete @range
    delete @radius
    delete @repeatsEvery
    delete @damage
    delete @duration

  attach: (thang) ->
    super thang
    thang.addSpell @_poisonCloudSpell
    
  castPoisonCloud: (target) ->
    @cast 'poison-cloud', target

  "perform_poison-cloud": ->
    @unhide?() if @hidden
    target = @target.pos or @target
    affected = (c for c in @getEnemies() when c.hasEffects and target.distance(c.pos) < @spells['poison-cloud'].radius)
    effect = {
      name: 'poison', duration: @spells['poison-cloud'].duration, targetProperty: 'health', repeatsEvery: @spells['poison-cloud'].repeatsEvery, addend: -@spells['poison-cloud'].damage
    }
    for t in affected
      t.effects = (e for e in t.effects when e.name isnt 'poison')
      t.addEffect effect
    args = [parseFloat(target.x.toFixed(2)),parseFloat(target.y.toFixed(2)),parseFloat(@spells['poison-cloud'].radius.toFixed(2)),'#BA55D3']
    @addCurrentEvent "aoe-#{JSON.stringify(args)}"

  "getTarget_poison-cloud": ->
    return null unless thangs = @getEnemies?()
    nearest = null
    nearestDistanceSquared = Infinity
    for thang in thangs
      continue unless @canCast 'poison-cloud', thang
      distanceSquared = @distanceSquared thang
      if distanceSquared < nearestDistanceSquared
        nearestDistanceSquared = distanceSquared
        nearest = thang
    return nearest
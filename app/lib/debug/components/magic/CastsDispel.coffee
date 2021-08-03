Component = require 'lib/world/component'

effectValues =
  'shrink': -1
  'slow': -2
  'confuse': -1
  'fear': -2
  'disintegrate': -3
  'poison-cloud': -2
  'root': -1
  'antigravity': -2

  'earthskin': 1
  'flame-armor': 2
  'haste': 2
  'invisibility': 2
  'raise-dead': 2
  'regen': 1
  'power-up': 2
  'power-up-2': 3
  'warcry': 1

module.exports = class CastsDispel extends Component
  @className: 'CastsDispel'

  constructor: (config) ->
    super config
    @_dispelSpell = name: 'dispel', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_dispelSpell
    thang.existenceSystem ?= thang.world.getSystem "Existence" 

  perform_dispel: ->
    for effect in @target.effects
      @target.undoEffectProportionally(effect)
    @target.effects = []
    targetEffects = [
      # Fake effect to get the dispel mark to show up
      {name: 'dispel', duration: 0.5, reverts: false, addend: 0, targetProperty: 'health', repeatsEvery: 0.5}
    ]
    @target.addEffect effect for effect in targetEffects

  getTarget_dispel: ->
    bestTarget = null
    bestTargetEffectValue = Infinity
    friends = (@getFriends?() ? []).concat [@]
    enemies = (@getEnemies?() ? [])
    rangeSquared = @spells.dispel.range * @spells.dispel.range
    for [valence, thangs] in [[1, friends], [-1, enemies]]
      for thang in thangs when @distanceSquared(thang) <= rangeSquared
        effectValue = 0
        for effect in thang.effects ? []
          effectValue += effectValues[effect.name] or 0
        power = @existenceSystem.buildTypePower[thang.type] or thang.maxHealth or 1
        if /Hero Placeholder/.test thang.id
          power = 9001
        effectValue *= Math.sqrt(power) * thang.health / thang.maxHealth
        effectValue *= valence
        if effectValue < bestTargetEffectValue
          bestTargetEffectValue = effectValue
          bestTarget = thang
    
    if bestTargetEffectValue < -1
      bestTarget
    else
      null

Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

module.exports = class CastsRegen extends Component
  @className: 'CastsRegen'
  
  constructor: (config) ->
    super config
    @_regenSpell = name: 'regen', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, repeatsEvery: @repeatsEvery, duration: @duration, health: @health
    delete @cooldown
    delete @specificCooldown
    delete @range
    delete @health
    delete @duration
    delete @repeatsEvery

  attach: (thang) ->
    super thang
    thang.addSpell @_regenSpell
    
  castRegen: (target) ->
    @cast 'regen', target
  
  perform_regen: ->
    @target.effects = (e for e in @target.effects when e.name isnt 'regen')
    effects = [
      {name: 'regen', duration: @spells.regen.duration, targetProperty: 'health', repeatsEvery: @spells.regen.repeatsEvery, addend: @spells.regen.health}
    ]
    @target.addEffect effect, @ for effect in effects

  getTarget_regen: ->
    return null unless thangs = @getFriends?()
    thangs = thangs.concat [@]
    mostDamaged = null
    mostDamage = 0
    for thang in thangs
      continue unless thang.health
      damage = thang.maxHealth - thang.health
      if damage > mostDamage
        mostDamage = damage
        mostDamaged = thang
    return mostDamaged
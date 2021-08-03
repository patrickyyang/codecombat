Component = require 'lib/world/component'

module.exports = class CastsFlameArmor extends Component
  @className: 'CastsFlameArmor'

  constructor: (config) ->
    super config
    @_flameArmorSpell = name: 'flame-armor', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, damage: @damage, duration: @duration, healthFactor: @healthFactor
    delete @duration
    delete @damage
    delete @healthFactor
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_flameArmorSpell

  'perform_flame-armor': ->
    @target.effects = (e for e in @target.effects when e.name isnt 'flame-armor')
    effects = [
      {name: 'flame-armor', duration: @spells['flame-armor'].duration, reverts: true, factor: @spells['flame-armor'].healthFactor, targetProperty: 'maxHealth'}
      {name: 'flame-armor', duration: @spells['flame-armor'].duration, revertsProportionally: true, factor: @spells['flame-armor'].healthFactor, targetProperty: 'health'}
      {name: 'flame-armor', duration: @spells['flame-armor'].duration, reverts: true, addend: @spells['flame-armor'].damage, targetProperty: 'damageReflection'}
    ]
    @target.addEffect effect, @ for effect in effects
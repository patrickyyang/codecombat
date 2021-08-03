Component = require 'lib/world/component'

module.exports = class CastsSacrifice extends Component
  @className: 'CastsSacrifice'

  constructor: (config) ->
    super config
    @_sacrificeSpell = name: 'sacrifice', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, efficiency: @efficiency
    
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_sacrificeSpell
    
  sacrifice: (target, sacrificeRecipient) ->
    @target = target
    @sacrificeRecipient = sacrificeRecipient
    
    perform_sacrifice()
  
  castSacrifice: (target, sacrificeRecipient) ->
    @sacrificeRecipient = null
    @cast 'sacrifice', target, sacrificeRecipient
    
  getAddend: (target, sacrificeRecipient, property) ->
    # This is affected by how much health the victim has remaining.
    if property is 'scale'
      return target.mass * @spells.sacrifice.efficiency / sacrificeRecipient.mass + 1
    if property is 'health'
      return target[property] * @spells.sacrifice.efficiency
    if property is 'attackDamage'
      # Must take into account DPS of both units
      return target.attackDamage / target.actions.attack.cooldown * sacrificeRecipient.actions.attack.cooldown * @spells.sacrifice.efficiency * target.health / target.maxHealth
    return target[property] * @spells.sacrifice.efficiency * target.health / target.maxHealth

  perform_sacrifice: ->
    
    return if @target.team isnt @team
    return if not @target.health > 0
    return if @target.type in ['arrow-tower', 'artillery', 'robot-walker', 'palisade', 'robobomb', 'catapult', 'beam-tower'] 
    
    @sacrificeRecipient ?= @castArguments?[0] or @
    
    effect.timeSinceStart = 9001 for effect in @target.effects
    @target.updateEffects()
    
    scaling = Math.min(2,@getAddend(@target, @sacrificeRecipient, 'scale'))
    
    #console.log 'scaling is', scaling, 'health', @getAddend(@target, @sacrificeRecipient, 'health'), @sacrificeRecipient.health
    #console.log 'attackDamage added:', @getAddend(@target, @sacrificeRecipient, 'attackDamage')
    #console.log 'target attackDamage:', @target.attackDamage, 'target attackSpeed', @target.actions.attack.cooldown
    #console.log 'recipient attackDamage:', @sacrificeRecipient.attackDamage, 'recipient attackSpeed', @sacrificeRecipient.actions.attack.cooldown
    #console.log 'adding', @getAddend(@target, @sacrificeRecipient, 'health'), 'health from', @target.id, 'of', @target.health, 'to', @sacrificeRecipient.id, 'of', @sacrificeRecipient.health
    
    effects = [
      {name: 'sacrifice', duration: 9001, reverts: false, addend: @getAddend(@target, @sacrificeRecipient, 'attackDamage'), targetProperty: 'attackDamage'}
      {name: 'sacrifice', duration: 9001, reverts: false, addend: @getAddend(@target, @sacrificeRecipient, 'health'), targetProperty: 'health'}
      {name: 'sacrifice', duration: 9001, reverts: false, addend: @getAddend(@target, @sacrificeRecipient, 'maxHealth'), targetProperty: 'maxHealth'}
      {name: 'sacrifice', duration: 9001, reverts: false, factor: 1 / Math.sqrt(Math.sqrt(scaling)), targetProperty: 'maxSpeed'}
      {name: 'sacrifice', duration: 9001, reverts: false, factor: scaling, targetProperty: 'mass'}
      {name: 'sacrifice', duration: 9001, reverts: false, factor: Math.sqrt(Math.sqrt(scaling)), targetProperty: 'scaleFactor'}
      {name: 'power-up-2', duration: 0.5, reverts: true, setTo: true, targetProperty: 'beingSacrificed'}
    ]
    @sacrificeRecipient.addEffect? effect, @ for effect in effects unless @sacrificeRecipient.dead
    
    @target.addEffect {name: 'curse', duration: 0.5, reverts: true, setTo: true, targetProperty: 'beingSacrificed'}
    @target.health = 0
    @target.keepTrackedProperty 'health'
    
    @target.die()
    @sacrificeRecipient = null
    
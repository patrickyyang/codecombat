Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Heals extends Component
  @className: 'Heals'

  attach: (thang) ->
    healAction = name: 'heal', cooldown: @cooldown, specificCooldown: @specificCooldown
    @healRange = @range
    delete @cooldown
    delete @specificCooldown
    delete @range
    super thang
    thang.addActions healAction

  heal: (target) ->
    target ?= @ if @isAttackable
    
    unless target?
      throw new ArgumentError "heal target is null.", "heal", "target", "object", target
    unless target.isAttackable
      throw new ArgumentError "Pass a unit with health to heal.", "heal", "target", "object", target
    
    @setTarget target, 'heal'
    @intent = 'heal'
    return unless @target # Naria's hide
    
    if @distance(@target, true) > @healRange
      @setAction 'move'
    else
      @setAction 'heal'
    return @block?()

  update: ->
    return unless @intent is 'heal'
    if @distance(@target, true) > @healRange
      return @setAction 'move'
    @setAction 'heal'
    return unless @act()
    @unblock?()
    @intent = undefined
    @target.health = Math.min @target.maxHealth, @target.health + @healAmount
    if @target.effects
      @target.effects = (e for e in @target.effects when e.name isnt 'heal')
      @target.addEffect {name: 'heal', duration: 0.5, reverts: true, setTo: true, targetProperty: 'beingHealed'}
    @setTarget null

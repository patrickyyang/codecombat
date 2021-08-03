Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class CastsConfuse extends Component
  @className: 'CastsConfuse'

  constructor: (config) ->
    super config
    @_confuseSpell = name: 'confuse', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, duration: @duration
    delete @cooldown
    delete @specificCooldown
    delete @range
    delete @duration

  attach: (thang) ->
    super thang
    thang.addSpell @_confuseSpell
    
  perform_confuse: ->
    target = @target
    onRevert = ->
      target.setTarget null
      target.setAction 'idle'
      target.movedOncePos = null
      target.castOnceTarget = null
      target.clearAttack?()
    @target.effects = (e for e in @target.effects when e.name isnt 'confuse')
    effects = [
      {name: 'confuse', duration: @spells.confuse.duration, reverts: true, setTo: @confusedChooseAction, targetProperty: 'chooseAction', onRevert: onRevert}
      {name: 'confuse', duration: @spells.confuse.duration, reverts: true, setTo: null, targetProperty: 'targetPos'}
    ]
    @target.addEffect effect, @ for effect in effects
    @target.endCurrentPlan?()
    
  confusedChooseAction: ->
    # This is what the enemy unit does while confused.
    @sayWithoutBlocking? 'Wha...?'
    nearestCombatant = @getNearestCombatant()
    if @attack and nearestCombatant and @distance(nearestCombatant) < 5
      @attack nearestCombatant
    else if @move
      @confusedDirection ?= new Vector(1000, 0).rotate @world.rand.randf() * Math.PI * 2
      @move @confusedDirection

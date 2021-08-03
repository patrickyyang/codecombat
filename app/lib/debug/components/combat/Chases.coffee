Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'
Vector = require 'lib/world/vector'

module.exports = class Chases extends Component
  @className: 'Chases'
  
  
  attach: (thang) ->
    chaseAction = name: "chase", specificCooldown: @specificCooldown, cooldown: 0
    delete @specificCooldown
    super thang
    thang.addActions chaseAction
  
  chase: (target) ->
    unless target and target.exists
      throw new ArgumentError "Target should be.", chase, "target", "unit", target
    unless target.isThang and target.isAttackable and target.isMovable and target.exists
      @sayWithoutBlocking "I can't chase it."
      return
    if target.health <= 0
      @sayWithoutBlocking "But it's dead."
      return
    if not @canSee target
      @sayWithoutBlocking "I don't see it."
      return
    maxHealth = 0
    if @chaseTargetMaxHealthFlat
      maxHealth = @chaseTargetMaxHealthFlat
    else if @commander and @commander.maxHealth and @chaseTargetMaxHealthRelative
      maxHealth = @commander.maxHealth * @chaseTargetMaxHealthRelative
    console.log(maxHealth)
    if target.health > maxHealth or /Hero\ Placeholder/i.test(target.id)
      @sayWithoutBlocking "It's too strong."
      return
    @setTarget target
    @setAction "chase"
    @intent = "chase"
    @block?()
    
  performChase: (target) ->
    @setAction "idle"
    @beforeChasePos = @pos.copy()
    @sayWithoutBlocking "ROAR!"
    onRevertChaser = =>
      if @beforeChasePos
        @setTargetPos @beforeChasePos
        @setAction "move"
      @stopChasing()
    @effects = (e for e in @effects when e.name not in ["haste", "chase"])
    effects = [
      {name: "chase", duration: @chaseDuration, reverts: true, setTo: @chaseChooseAction.bind(@), targetProperty: "chooseAction", onRevert: onRevertChaser}
      {name: "haste", duration: @chaseDuration, reverts: true, factor: @chaseSpeedFactor, targetProperty: "maxSpeed"}
      #{name: 'haste', duration: @chaseDuration, reverts: true, targetProperty: 'commander', setTo: @}
    ]
    @addEffect effect, @ for effect in effects
    @endCurrentPlan?()
    onRevert = ->
      target.setTarget null
      target.setAction 'idle'
      target.movedOncePos = null
      target.castOnceTarget = null
      target.clearAttack?()
    target.effects = (e for e in target.effects when e.name not in ["fear", "chased"])
    target.beforeChooseAction = target.chooseAction
    effects = [
      {name: "chased", duration: @chaseDuration, reverts: true, setTo: @chasedChooseAction.bind(target), targetProperty: "chooseAction", onRevert: onRevert}
      {name: "chased", duration: @chaseDuration, reverts: true, setTo: @chaseCloseRange * 2, targetProperty: "chaseFleeRange"}
      {name: "chased", duration: @chaseDuration, reverts: true, setTo: @, targetProperty: "chaser"}
      {name: 'fear', duration: @chaseDuration, reverts: true, targetProperty: 'commander', setTo: @}
    ]
    target.addEffect effect, @ for effect in effects
    target.endCurrentPlan?()
  
  update: () ->
    if @action is "chase" and not @hasEffect("chase") and @act()
      @performChase(@target)

  chasedChooseAction: ->
    unless @chaser and @chaseFleeRange and (@distanceTo(@chaser) <= @chaseFleeRange)
      @beforeChooseAction?()
      return
    dir = @pos.copy().subtract(@chaser.pos).normalize().multiply(@maxSpeed * @world.dt * 2)
    fleePos = @pos.copy().add(dir)
    #console.log(@pos, fleePos, @aiSystem?, )
    if @aiSystem and @aiSystem.isPathClear(@pos, @pos.copy().add(dir), @, true)
      @move @pos.copy().add(dir)
    else
      @setAction "idle"
      @sayWithoutBlocking "Aaaa!!!", 1

  
  chaseChooseAction: ->
    if @target and @target.exists and @target.health >= 0
      if @distanceTo(@target) >= @chaseCloseRange
        @setAction "move"
      else
        @setAction "idle"
        @brake?()
    else
      @stopChasing()
    
  
  stopChasing: () ->
    for effect in @effects when effect.name is "chase"
      effect.timeSinceStart = 9001
    @intent = null
    @unblock?()
    
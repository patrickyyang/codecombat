Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'
Vector = require 'lib/world/vector'

module.exports = class Charms extends Component
  @className: 'Charms'
  
  constructor: (config) ->
    super config
    @charmDistanceSquared = @charmDistance * @charmDistance
  
  attach: (thang) ->
    charmAction = name: "charm", specificCooldown: @specificCooldown, cooldown: 0.1
    delete @specificCooldown
    super thang
    thang.addActions charmAction
  
  charm: (target) ->
    unless target and target.exists
      throw new ArgumentError "Target should be.", chase, "target", "unit", target
    unless target.isThang and target.isAttackable and target.exists
      @sayWithoutBlocking "I can't charm it."
      return
    if target.health <= 0
      @sayWithoutBlocking "But it's dead."
      return
    if not @canSee target
      @sayWithoutBlocking "I don't see it."
      return
    maxHealth = 0
    if @commander and @commander.maxHealth and @charmTargetMaxHealthRelative
      maxHealth = @commander.maxHealth * @charmTargetMaxHealthRelative
    if target.health > maxHealth or /Hero\ Placeholder/i.test(target.id)
      @sayWithoutBlocking "It's too strong."
      return
    @setTarget target
    @intent = "charm"
    @block?()
    
  performCharm: (target) ->
    @intent = null
    @unblock?()
    @setAction "idle"
    #@beforeChasePos = @pos.copy()
    @sayWithoutBlocking "Protect me!"
    onRevert = ->
      target.setTarget null
      target.setAction 'idle'
      target.movedOncePos = null
      target.castOnceTarget = null
      target.clearAttack?()
    target.effects = (e for e in target.effects when e.name not in ["fear", "chased"])
    target.beforeChooseAction = target.chooseAction
    target.sayWithoutBlocking "It's so cute."
    effects = [
      {name: "charm", duration: @charmDuration, reverts: true, setTo: @charmChooseAction.bind(target), targetProperty: "chooseAction", onRevert: onRevert}
      {name: "charm", duration: @charmDuration, reverts: true, setTo: true, targetProperty: "isCharmed"}
      {name: "charm", duration: @charmDuration, reverts: true, setTo: @team, targetProperty: "team"}
      {name: "charm", duration: @charmDuration, reverts: true, setTo: @superteam, targetProperty: "superteam"}
      {name: "charm", duration: @charmDuration, reverts: true, setTo: @, targetProperty: "charmMaster"}
    ]
    target.addEffect effect, @ for effect in effects
    target.updateEffects "charm"
    target.updateRegistration()
    target.endCurrentPlan?()
  
  update: () ->
    if @intent is "charm" and @target
      if @distanceSquared(@target) < @charmDistanceSquared
        @setAction "charm"
      else
        @setAction "move"
    if @action is "charm" and @act()
      @performCharm(@target)

  charmChooseAction: ->
    return unless @charmMaster
    enemy = @findNearest(en for en in @charmMaster.findEnemies?() when en isnt @)
    if enemy
      @attack?(enemy)
    else
      dir = @pos.copy().subtract(@charmMaster.pos).normalize()
      pos = @charmMaster.pos.copy().add(dir.multiply(3))
      @move pos
      

  
Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class CarriesUnit extends Component
  @className: 'CarriesUnit'
  
  #attach: (thang) ->
    #carryUnitAction = name: "carry-unit", specificCooldown: @specificCooldown, cooldown: 0, duration: @duration
    #delete @specificCooldown
    #delete @duration
    #super thang
    #thang.addActions carryUnitAction
  
  carryUnit: (target, x, y) ->
    return unless @commander
    if isNaN(x + y)
      throw new ArgumentError "Coordinates should be numbers.", "carryUnit", "x", "coordinate", x
    unless target and target.exists
      throw new ArgumentError "Target should exist.", "carryUnit", "target", "unit", target
    unless target.isThang and target.isAttackable and target.isMovable and target.exists
      @sayWithoutBlocking "I can't carry it."
      return
    @carryEndPos = new Vector(x, y)
    if target.health <= 0
      @sayWithoutBlocking "But it's dead."
      return
    #if not @canSee target
      #@sayWithoutBlocking "I don't see it."
      #return
    maxHealth = 0
    if @commander and @commander.maxHealth
      maxHealth = @commander.maxHealth * @carryUnitHealthRatio
    if target.health > maxHealth or /Hero\ Placeholder/i.test(target.id)
      @sayWithoutBlocking "It's too strong."
      return
    @setTarget target
    @intent = "carry-unit"
    @setAction "move"
    return @block?()
  
  
  update: () ->
    if @carriedUnit
      if @distanceSquared(@carryEndPos) < 1 or @carriedUnit.health <= 0
        @stopCarryUnit()
      else
        @setTargetPos @carryEndPos
        @setAction "move"
    else if @intent is "carry-unit" and @target
      if @distanceSquared(@target) < 4
        @performCarryUnit(@target)
    
  
  performCarryUnit: (target) ->
    @setTarget null
    @setTargetPos @carryEndPos
    @pos.z += target.depth + 2
    
    target.effects = (e for e in target.effects when e.name isnt "carried")
    target.beforeChooseAction = target.chooseAction
    effects = [
      {name: "carried", duration: 9001, reverts: true, setTo: @carriedChooseAction.bind(target), targetProperty: "chooseAction"}
    ]
    target.carrier = @
    target.beforeZPos = @pos.z
    @carriedUnit = target
    target.addEffect effect, @ for effect in effects
    target.endCurrentPlan?()
  
  carriedChooseAction: ->
    @setAction "idle"
    @pos = new Vector(@carrier.pos.x, @carrier.pos.y, @carrier.pos.z - @depth - 1) if @carrier
    @velocity.z = 0
  
  stopCarryUnit: () ->
    return unless @carriedUnit
    for effect in @carriedUnit?.effects when effect.name is "carried"
      effect.timeSinceStart = 9001
    @pos.z = @beforeZPos ? @height
    @brake?()
    @carriedUnit.carrier = null
    @carriedUnit = null
    @intent = undefined
    @setTarget null
    @setAction 'idle'
    @unblock?()
    
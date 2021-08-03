Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'
Vector = require 'lib/world/vector'

module.exports = class Throws extends Component
  @className: 'Throws'

  attach: (thang) ->
    throwAction = name: 'throw', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    @thrownMissileThangType = (@requiredThangTypes ? [])[0]
    thang.requiredThangTypes = (thang.requiredThangTypes ? []).concat(@requiredThangTypes ? [])
    thang.componentsForThangType @thrownMissileThangType if @thrownMissileThangType  # Make sure the Components are saved to the world's classMap.
    delete @requiredThangTypes
    super thang
    thang.addActions throwAction

  performThrow: (targetOrPos) ->
    # This is called in the Combat System
    @configureThrownMissile() unless @thrownMissileComponents
    return unless @thrownMissileComponents
    @unblock?()
    @intent = undefined
    @unhide?() if @hidden
    @lastMissileThrown = @spawn @thrownMissileSpriteName, @thrownMissileComponents
    @lastMissileThrown.launch? @, 'throw'
    @brake?()
    @sayWithoutBlocking? "Take that!"
    @lastMissileThrown
    
  configureThrownMissile: ->
    if @thrownMissileThangType
      @thrownMissileComponents = _.cloneDeep @componentsForThangType @thrownMissileThangType
      @thrownMissileSpriteName = _.find(@world.thangTypes, original: @thrownMissileThangType)?.name ? @thrownMissileThangType
    if @thrownMissileComponents?.length
      if allied = _.find(@thrownMissileComponents, (c) -> c[1].team)
        allied[1].team = @team
    else
      console.log @id, "Throws problem: couldn't find missile to throw for type", @thrownMissileThangType

  performThrownAttack: (target, damageRatio=1, momentum=null) ->
    momentum ?= @getThrowMomentum target.pos ? target
    target.takeDamage? @throwDamage * damageRatio, @, momentum
    #console.log @id, "hit", target.id, "with throw for", @throwDamage * damageRatio, 'damage; hp', target.health, 'momentum', momentum, 'from throwMass', @throwMass, 'throwZAngle', @throwZAngle

  getThrowMomentum: (targetPos) ->
    return null unless @throwMass
    dir = targetPos.copy().subtract(@pos).normalize()
    dir.z = Math.sin 0.2  # Assume throwZAngle of 0.2; probably don't want to configure per weapon.
    dir.normalize().multiply @throwMass, true

  canThrow: ->
    return false unless @canAct('throw') and targetPos = @getTargetPos()
    distance = @distance targetPos, false
    distance - 0.5 <= @throwRange

  # Confusing. doThrow? initThrow? beginThrowing?
  setThrow: ->
    @intent = 'throw'
    @announceAction? 'throw'
    target = @target or @targetPos
    if target and @actions.move and @chasesWhenAttackingOutOfRange and @distance(@getTargetPos(), false) - 0.5 > @throwRange
      @currentSpeedRatio = 1
      @setAction 'move'
    else
      if @distance(@getTargetPos(), false) > @throwRange
        @currentSpeedRatio = 1
        @setAction 'move'
      else
        @setAction 'throw'
    return @block?() unless @commander?

  throw: (target) ->
    if typeof target is 'undefined' or (not target? and @hasEnemies())
      throw new ArgumentError "throw target is null.", "throw", "target", "object", target
    unless target
      @setAction 'idle'
      @setTarget null
    @setTarget target, 'throw'
    @setThrow()

  throwPos: (targetPos) ->
    if typeof targetPos is 'undefined'
      throw new ArgumentError "You need a position to throw at.", 'throwPos', "targetPos", "object", targetPos
    # Argument errors
    @setTargetPos targetPos, 'throw'
    @setThrow()

  throwXY: (x, y, z) ->
    # Same as throwPos, but easier coordinates.
    for k in [["x", x], ["y", y], ["z", z]]
      unless (_.isNumber(k[1]) and not _.isNaN(k[1]) and k[1] isnt Infinity) or (k[0] is "z" and not k[1]?)
        throw new ArgumentError "Throw at an {x: number, y: number} position.", "throwXY", k[0], "number", k[1]
    @throwPos new Vector x, y, z

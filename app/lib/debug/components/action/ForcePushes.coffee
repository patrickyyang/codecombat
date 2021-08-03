Component = require 'lib/world/component'
Vector = require 'lib/world/vector'
{ArgumentError} = require 'lib/world/errors'

module.exports = class ForcePushes extends Component
  @className: 'ForcePushes'
  
  constructor: (config) ->
    super(config)
    @forcePushRangeSquared = @forcePushRange * @forcePushRange
    # We're using the perfect elastic collision formula
    # so v2 = v1 * sqrt(m1 / m2), v1 * sqrt(m1) can be transformed in comstant
    @forcePushConstant = @forcePushVelocity * Math.sqrt(@forcePushMass)
    @forcePushConstant
  
  attach: (thang) ->
    forcePushAction = {name: "force-push", cooldown: @cooldown, specificCooldown: @specificCooldown, range: @forcePushRange}
    super(thang)
    delete(@cooldown)
    delete(@specificCooldown)
    thang.addActions(forcePushAction)
  
  forcePush: (target, direction, forceRatio) ->
    unless target?
      throw new ArgumentError "Target is null. Is there always a target to push? (Use if?)", "forcePush", "target", "object", target
    unless direction.isVector? or not isNaN(direction.x + direction.y)
      throw new ArgumentError "The direction should a vector or an object with x, y and z (optional) properties.", "forcePush", "direction", "object", direction
    if isNaN(forceRatio) and (forceRatio < 0 or forceRation > 1)
      throw new ArgumentError "The forceRatio should be a number in [0, 1] range.", "forcePush", "forceRatio", "number", forceRatio
    @setTarget(target, 'force-push')
    unless @target and @target.mass? and (@target.collisionType is "dynamic")
      @sayWithoutBlocking("I can't push it.")
      return
    @forcePushDirection = direction.copy()
    @forcePushDirection.z ?= 0
    @forcePushDirection.normalize(true)
    @forcePushValue = @forcePushConstant * forceRatio
    @intent = "force-push"
    return @block?() unless @commander?
  
  performForcePush: () ->
    @unhide?() if @hidden
    if not @target or @target.hidden
      @sayWithoutBlocking("Where is the target?")
    @rotation = @target.pos.copy().subtract(@pos).heading()
    @keepTrackedProperty("rotation")
    velocityValue = @forcePushValue / Math.sqrt(@target.mass)
    dir = @forcePushDirection.multiply(velocityValue, true)
    @target.velocity ?= Vector(0, 0, 0)
    @target.velocity.add(dir, true)
    @target = null
    
  
  update: () ->
    return unless @intent is "force-push"
    if @distanceSquared > @forcePushRangeSquared
      @setAction("move")
    else
      @setAction("force-push")
    if @action is "force-push" and @act()
      @intent = null
      @performForcePush()
      @unblock()?
      @setAction("idle")
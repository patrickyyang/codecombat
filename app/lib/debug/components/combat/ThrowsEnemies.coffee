Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class ThrowsEnemies extends Component
  @className: "Throws"
  
  attach: (thang) ->
    throwAction = name: 'throw', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions throwAction

  throw: (target, toPos) ->
    if typeof target is 'undefined' or (not target? and @hasEnemies())
      # If there are no enemies left, don't sweat it--they've killed everyone anyway.
      throw new ArgumentError "#{@id} needs something to throw.", "throw", "target", "object", target
    if toPos? and (not toPos.x? or not toPos.y?)
      throw new ArgumentError "#{@id} should throw toward which {x, y} position?", "throw", "toPos", "object", target
    unless target
      @setAction 'idle'
      @setTarget null
      return
    @setTarget target, 'throw'
    @throwToTargetPos = if toPos then new Vector toPos.x, toPos.y else null
    if @distance(target, true) > @throwRange
      @currentSpeedRatio = 1
      return @setAction 'move'
    @setAction 'throw'

  canThrow: ->
    return false unless @canAct() and @target?.isMovable
    distance = @distance @target, true
    distance - 0.5 <= @throwRange

  getThrowMomentum: (target, targetPos) ->
    if @throwToTargetPos
      dir = @throwToTargetPos.copy().subtract(@target.pos).normalize()
    else
      dir = @pos.copy().subtract(target.pos).normalize()
    dir.z = if @throwZAngle then Math.sin @throwZAngle else 0
    dir.multiply @throwMass, true
    dir

  performThrow: (target) ->
    @unhide?() if @hidden
    momentum = @getThrowMomentum target, target.pos
    target.velocity.multiply 0, true
    target.velocity.add Vector.divide(momentum, target.mass, true), true
    target.pos.z += @pos.z
    if @throwToTargetPos
      dir = @throwToTargetPos.copy().subtract(target.pos).normalize()
    else
      dir = @pos.copy().subtract(target.pos).normalize()
    dir.multiply(2 + (Math.max(@width, @height) * Math.sqrt(2) / 2)) # outside of the unit's area, with some buffer (2m)
    target.pos = @pos.copy().add(dir, true)
    target.health -= @throwDamage if target.health?
    if target.hasEffects
      target.addEffect {name: 'confuse', duration: 1.5, reverts: true, factor: 0.01, targetProperty: 'actionTimeFactor'}

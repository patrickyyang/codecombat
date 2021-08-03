Component = require 'lib/world/component'

{STANDARD_FRICTION, AIR_DENSITY, WATER_DENSITY} = require 'lib/world/systems/movement'
Vector = require 'lib/world/vector'
{ArgumentError} = require 'lib/world/errors'

module.exports = class Moves extends Component
  @className: 'Moves'
  isMovable: true
  hasMoved: false
  constructor: (config) ->
    super config
    @pathRefreshCounter = 0
    @moveThreshold = 0.1  # How many meters away from the target before a planned move or simpleMove completes
    @_moveCooldown = @cooldown
    delete @cooldown

  attach: (thang) ->
    super thang
    thang.velocity = new Vector @velocity?.x or 0, @velocity?.y or 0, @velocity?.z or 0
    thang.addTrackedProperties ["pos", "Vector"], ['velocity', "Vector"]
    if thang.acts and thang.maxAcceleration > 0
      thang.addActions name: 'move', cooldown: @_moveCooldown
    thang.aiSystem = thang.world.getSystem("AI")

  manageFrustration: (dist) ->
    (@recentDistances ?= []).push dist
    if @recentDistances.length is Math.round @world.frameRate
      recentDist = @recentDistances.shift()
      if Math.abs(recentDist - dist) > 2
        if @currentlySaying?.message is "I can't get there."
          @say? ""
        @movingSince = @world.age

  endMultiFrameMove: ->
    @multiFrameMove = false
    @unblock?()
    @setTargetPos null
    @movingSince = null
    @recentDistances = []
    @setAction 'idle'
    #@brake() if @commander  # TODO: check this out, see if it helps for baby griffin pets and the like in general
    
  update: ->
    return unless @multiFrameMove and @action is 'move' 
    dist = @distance(@getTargetPos())
    @manageFrustration(dist)
    idleTime = @world.age - @movingSince
    if dist < @moveThreshold
      @endMultiFrameMove()
    else if idleTime > 1.5 + 2
      @endMultiFrameMove()
    else if Math.abs(idleTime - 2) <= @world.dt
      if @recentDistances? and Math.abs(@recentDistances[0] - dist) < 0.5
        @sayWithoutBlocking? "I can't get there."

  move: (pos) ->
    if not pos?
      throw new ArgumentError "Target an {x: number, y: number} position.", "move", "pos", "object", pos
    # TODO: Genius way to set ourselves to idle if we finish this move without interfering with showing our action (like if we stop telling our pet to do something)
    @intent = undefined
    @setTargetPos pos, 'move'
    @setAction 'move'
    return @block?() unless @commander?

  moveXY: (x, y, z) ->
    if !x? or !y?
      throw new ArgumentError "moveXY requires 2 numbers as arguments, x and y.", "moveXY", "_excess", "number", x
    for k in [["x", x], ["y", y], ["z", z]]
      unless (_.isNumber(k[1]) and not _.isNaN(k[1]) and k[1] isnt Infinity) or (k[0] is "z" and not k[1]?)
        throw new ArgumentError "moveXY requires 2 numbers as arguments. " + k[0] + " is " + k[1] + " which is type \'" + (typeof k[1]) + "\', not \'number\'.", "moveXY", k[0], "number", k[1], 2
    @intent = undefined
    @setTargetPos {x: x, y: y, z: z}, 'moveXY'
    @setAction 'move'
    @movingSince = @world.age
    @multiFrameMove = true
    return @block?() unless @commander? and not @actionsShouldBlock

  follow: (target) ->
    if typeof target is 'undefined'
      throw new ArgumentError "#{@id} needs something to follow.", "follow", "target", "unit", target
    @setTarget target, "follow"
    @setAction 'move'

  locomote: ->
    # To optimize...
    # Get us to our desired maxSpeed, within the limits of our maxAcceleration, pointing toward the target.
    if @world.gameGravity and not @ignoreGravity
      dt = @actions?.move?.cooldown or @world.dt
      targetPos = @getTargetPos()
      straightCourse = Vector.subtract targetPos, @pos
      straightCourse.x = 0 if @world.gameGravity.x
      straightCourse.y = 0 if @world.gameGravity.y
      distance = straightCourse.magnitude()
      targetSpeed = @maxSpeed * (@currentSpeedRatio ? 1)
      targetVelocity = straightCourse.copy().normalize().multiply(targetSpeed).limit distance / @world.dt
      currentVelocityOrthogonalToGravity = Vector.copy @velocity
      currentVelocityOrthogonalToGravity.x = 0 if @world.gameGravity.x
      currentVelocityOrthogonalToGravity.y = 0 if @world.gameGravity.y
      correctiveVelocity = Vector.subtract(targetVelocity, currentVelocityOrthogonalToGravity).limit @maxAcceleration / @world.dt
      if distance > 0.5
        @rotation = straightCourse.heading()
        @hasRotated = true
      @locomotiveForce = Vector.multiply correctiveVelocity, @mass / dt
      console.log 'locomotive force', @locomotiveForce if @type is 'goliath'
      return @locomotiveForce

    else if @isAirborne() and @locomotionType isnt "flying"
      return new Vector(0, 0, 0)
    
    dt = @actions?.move?.cooldown or @world.dt
    targetPos = @getTargetPos()
    unless targetPos
      # Just move in direction we're facing
      targetPos = new Vector(20, 0).rotate(@rotation).add @pos
    else if @findsPaths and @aiSystem?.findsPaths
      @path = null if @lastTarget and (not @lastTarget.equals targetPos)
      @path = null if @pathRefreshCounter++ % 20 is 0
      @path ?= @aiSystem.findPath(@pos, targetPos, Math.max(@width, @height) / 2)
      @lastTarget = targetPos.copy()
      #console.log @id, 'got path', @path, 'from', @pos.x, @pos.y, 'to', @lastTarget.x, @lastTarget.y, 'at time', @world.age

      # If units move in bunches along the same path, they keep each other from hitting their marks
      # and end up walking into each other indefinitely. This check sees if they 'passed' the point, and move on if so.
      checkPastPoint = true
      while @path?.length and @pos.distance(@path[0]) < 0.05 * dt / @world.dt
        checkPastPoint = false
        @path.shift()
        @shiftPastRight = @path.length and @path[0].x - @pos.x > 1
        @shiftPastLeft = @path.length and @path[0].x - @pos.x < -1
        @shiftPastTop = @path.length and @path[0].y - @pos.y > 1
        @shiftPastBottom = @path.length and @path[0].y - @pos.y < -1

      if checkPastPoint and @path?.length
        shouldShift = true
        shouldShift = false if @shiftPastRight and @path[0].x > @pos.x
        shouldShift = false if @shiftPastLeft and @path[0].x < @pos.x
        shouldShift = false if @shiftPastTop and @path[0].y > @pos.y
        shouldShift = false if @shiftPastBottom and @path[0].y < @pos.y
        @path.shift() if shouldShift
      
      targetPos = @path[0] if @path?[0]?
    nearnessThreshold = 0
    nearnessThreshold = 5 if @team and @target?.team is @team and targetPos.equals(@target.pos) and (not @intent? or @intent is 'move') # Stop before reaching friendly units
    straightCourse = Vector.subtract targetPos, @pos
    straightCourse.limit Math.max(0, straightCourse.magnitude() - nearnessThreshold)
    distance = straightCourse.magnitude()
    # https://github.com/codecombat/codecombat/issues/1112
    #if distance < @moveThreshold  # Already there, so don't move/rotate
    #  return new Vector(0, 0, 0)
    targetSpeed = @maxSpeed * (@currentSpeedRatio ? 1)
    targetVelocity = straightCourse.copy().normalize().multiply(targetSpeed).limit distance / @world.dt
    correctiveVelocity = Vector.subtract(targetVelocity, @velocity).limit @maxAcceleration / @world.dt
    if distance > 0.5
      @rotation = straightCourse.heading()
      @hasRotated = true
    @locomotiveForce = Vector.multiply correctiveVelocity, @mass / dt
    @locomotiveForce

  maintainsElevation: ->
    @locomotionType is "flying" and @actions?.move and not @dead
    
  brake: ->
    return unless @isGrounded() or @maintainsElevation()
    return if @world.getSystem("Movement").frictionAt(@pos, 1) is 0 and @isGrounded()
    return unless @world.gravity
    @velocity.limit Math.max(0, @velocity.magnitude() - @maxAcceleration / @world.dt)

  calculateDrag: (density=null, velocity=null) ->
    return new Vector() unless @world.gravity
    # To optimize...
    density ?= if @locomotionType is "swimming" then WATER_DENSITY else AIR_DENSITY
    velocity ?= @velocity
    speed = velocity.magnitude()
    console.log "No drag area for", @id, "-- is Physical Component attached?" unless @dragArea?
    drag = Vector.multiply velocity, -0.5 * density * speed * @dragCoefficient * @dragArea

  calculateRollingResistance: (density=null, friction=null, velocity=null) ->
    # To optimize...
    # Not just real rolling resistance, but all internal dissipation of energy
    return new Vector() if not @isGrounded() or @velocity.z > 0 or not @world.gravity
    density ?= if @locomotionType is "swimming" then WATER_DENSITY else AIR_DENSITY
    friction ?= STANDARD_FRICTION
    velocity ?= @velocity
    rollingResistance = @rollingResistance
    if @locomotionType is "swimming" and density < 100  # can't keep swimming afloat
      rollingResistance += 0.5
    if @health < 0
      # Add more internal friction to dead Thangs
      rollingResistance = 0.4 + 2 * @rollingResistance
    if @locomotionType is "rolling"
      # Rolling resistance is only at minimum when locomotiveForce and velocity are aligned. When right angles or worse, it's 1 (brakes).
      # http://www.asawicki.info/Mirror/Car%20Physics%20for%20Games/Car%20Physics%20for%20Games.html (but ignore the Crr values there)
      actualHeading = velocity.heading()
      if actualHeading < 0 then actualHeading += 2 * Math.PI
      intendedHeading = if @rotation < 0 then @rotation + 2 * Math.PI else @rotation
      headingDifference = (intendedHeading - actualHeading) % (2 * Math.PI)
      rollingResistance += Math.abs(headingDifference / (Math.PI / 2)) * (1 - rollingResistance)
    return new Vector() unless rollingResistance
    rollingResistance *= friction
    if @rollingResistanceCalculatedOnce and @action isnt "move"  # list other moving actions, too
      rollingResistance *= 5  # They're not trying to move, so they're probably trying to stop
    @rollingResistanceCalculatedOnce = true
    fRR = velocity.copy().normalize().multiply -@world.gravity * @mass * rollingResistance

Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class JumpsToTarget extends Component
  @className: "JumpsToTarget"
  jumpSpeedFactor: 1
  
  update: ->
    if @action is 'jump' and @isGrounded() and @actionActivated and targetPos = @getTargetPos()
      # We just jumped and we have a target, so let's set our x/y velocity to aim at it.
      # Jumps' update will unblock
      jumpSpeed = @maxSpeed * @jumpSpeedFactor
      jumpVector = Vector.subtract(targetPos, @pos)
      jumpDistance = jumpVector.magnitude()
      jumpTime = Math.max @world.dt, Math.min(@jumpTime, jumpDistance / jumpSpeed)
      @velocity.z = @world.gravity * jumpTime / 2
      jumpVector.normalize().multiply jumpSpeed
      @velocity.x = jumpVector.x
      @velocity.y = jumpVector.y
      @rotation = @velocity.heading()
      @hasRotated = true
      #console.log @id, "jumping from", @pos.x, @pos.y, @pos.z, "to", targetPos.x, targetPos.y, targetPos.z, "with v", @velocity.x, @velocity.y, @velocity.z, "out of max speed", jumpSpeed, "normal maxSpeed", @maxSpeed, "JSF", @jumpSpeedFactor

  jumpTo: (target) ->
    if typeof target is 'undefined'
      throw new ArgumentError "You need somewhere to jumpTo.", "jumpTo", "target", "object", target
    if target?.pos
      @setTarget target, 'jumpTo'
    else
      @setTargetPos target, 'jumpTo'
    return @jump()  # jump() will block

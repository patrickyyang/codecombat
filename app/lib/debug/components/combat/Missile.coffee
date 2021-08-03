Component = require 'lib/world/component'

Vector = require 'lib/world/vector'

# Not really named adverbially...
module.exports = class Missile extends Component
  @className: "Missile"
  isMissile: true
  attach: (thang) ->
    super thang
    thang.setExists false if thang.world.age is 0 and not /Portal/.test(thang.id)  # We could get rid of this if we were willing to migrate all the old levels with missile template Thangs.

  findInterception: (from, to, targetVelocity, speed, useZ) ->
    # http://www.gamedev.net/topic/457840-calculating-target-lead/
    diff = Vector.subtract(to, from)
    a = targetVelocity.dot(targetVelocity) - speed * speed
    b = 2 * targetVelocity.dot(diff)
    c = diff.dot(diff)
    d = b * b - 4 * a * c
    t = 0
    unless d < 0 or a is 0
      t0 = (-b - Math.sqrt(d)) / (2 * a)
      t1 = (-b + Math.sqrt(d)) / (2 * a)
      t = if t0 < 0 then t1 else (if t1 < 0 then t0 else Math.min(t0, t1))
    if t <= 0 then t = @lifespan ? 3 
    {pos: Vector.add(to, Vector.multiply(targetVelocity, t, useZ), useZ), time: t}

  launch: (shooter, launchType='attack') ->
    @launchType = launchType
    @setExists true
    @shooter = shooter
    @pos = Vector.add @shooter.pos, {x: 0, y: 0, z: @pos.z}, true  # Physical pos as offset to shooter pos, but only in z dimension
    @pos.z = Math.min @pos.z, @depth / 2 + 1  # Make sure we start at least a meter off the ground
    targetPos = @shooter.getTargetPos().copy()
    targetPos.z = 0 if @shootsAtGround
    if @leadsShots and @shooter.target?.velocity?.magnitude() > 0
      if @flightTime
        targetPos.add Vector.multiply(@shooter.target.velocity, @flightTime, not @shootsAtGround)
      else
        interception = @findInterception @pos, targetPos, @shooter.target.velocity, @maxSpeed, not @shootsAtGround
        targetPos = interception.pos
        @flightTime = interception.time
      unless @shootsAtGround or @shooter.target.maintainsElevation?()
        # Account for gravity when leading target z. TODO: this doesn't work properly.
        targetPos.z = Math.max((if @shooter.target.depth then @shooter.target.depth / 2 else 0), targetPos.z - @world.gravity * @flightTime * @flightTime / 2)
    @setTargetPos targetPos
    @addCurrentEvent? 'launch'
    
Component = require 'lib/world/component'

{MAX_COOLDOWN} = require 'lib/world/systems/action'

# This can do spears and other similar projectiles, too. Bad name!!
module.exports = class Arrow extends Component
  @className: "Arrow"
  
  attach: (thang) ->
    super thang
    if thang.acts
      thang.addActions name: 'die', cooldown: MAX_COOLDOWN

  launch: (shooter, launchType='attack') ->
    # Assumes Missile launch has already been called, so we have @targetPos and @pos computed.
    @launchType = launchType
    @velocity.x = @targetPos.x - @pos.x
    @velocity.y = @targetPos.y - @pos.y
    if @leadsShots and @shooter.target?.velocity?.magnitude() > 0 and @distance(@shooter.target.pos) <= @shooter[@launchType + 'Range']
      # It's in range, but will move out of range, so let's make sure we still shoot it.
      @calculatedAttackDistance = distance = @velocity.magnitude()
    else
      # Shoot only as far as we need to, and also not further than our attackRange.
      @calculatedAttackDistance = distance = Math.min @velocity.magnitude(), @shooter[@launchType + 'Range']
    if @maximizesArc and distance > @targetPos.z - @pos.z  # Can shoot at 45-degree angle, and want to.
      @calculateArcVelocity distance
    else
      @calculateStraightVelocity distance
    @rotation = @velocity.heading() % (2 * Math.PI)
    @hasRotated = true
    @velocity.z += @world.dt * @world.gravity / 2  # Give it a little extra boost to make sure it hits its target
    #console.log @shooter.id, @id, "got v", @velocity, "from", @pos, "to", @targetPos, "with distance", (@getTargetPos().distance @pos), "intended distance", distance
    
  calculateStraightVelocity: (distance) ->
    # Calculate if the arrow would still be in the air when reaching the attackRange and use 0 as target z instead in this case.
    if ((@pos.z * @velocity.magnitude()) / (@pos.z - @targetPos.z)) > @calculatedAttackDistance
      targetZ = 0
    else if @launchType is 'attack' and @team and @shooter.target?.team is @team
      # Don't let people shoot missiles at friends that would then travel very long distances and hit enemies out of range
      targetZ = 0
    else    
      targetZ = @targetPos.z
    
    @velocity.normalize().multiply @maxSpeed  # m/s
    time = distance / @maxSpeed
    @velocity.z = (targetZ - @pos.z) / time  # + @world.gravity * time / 2  # Mike's way of adjusting for gravity

    # adjust for gravity
    @velocity.z += @world.gravity * Math.min(time, (@calculatedAttackDistance / @maxSpeed)) / 2
    
  calculateArcVelocity: (distance) ->
    # notice we don't look at @maxSpeed, because slow maxSpeed doesn't actually result in slow projectile,
    # but instead makes a short-flying one
    angle = Math.PI / 4 
    desiredSpeed = distance * Math.sqrt(@world.gravity / (distance - @targetPos.z + @pos.z))
    @velocity.normalize().multiply(desiredSpeed * Math.cos(angle))  # m/s
    @velocity.z = desiredSpeed * Math.sin(angle)

  beginContact: (thang) ->
    return unless @exists
    # console.log @id, "beginContact", thang.id, thang.exists, thang.isAttackable, thang.health, @velocity.magnitude()
    hitMeat = thang.exists and thang.isAttackable and not @velocity.isZero(true)
    if hitMeat
      # Do less damage if we hit significantly slower
      damageRatio = Math.min 1, @velocity.magnitude(true) / @maxSpeed
      # .. unless we're in the dungeon and need to alwaysHit
      if @alwaysHits
        damageRatio = 1
      
      # console.log @shooter.id, @id, "hit", thang.id, "from", @id, "with velocity", @velocity, @velocity.magnitude(true), damageRatio
      if @launchType is 'attack'
        @shooter.performAttackOriginal thang, damageRatio
      else if @launchType is 'throw'
        @shooter.performThrownAttack thang, damageRatio
    willDie = hitMeat or @diesOnHit
    if willDie
      @velocity.multiply 0, true
      @collidedWith = thang
      @fixedRotation = true  # don't change our rotation based on this collision. TODO: find a way to actually cancel/die/destroy here instead of next frame
      @addCurrentEvent 'hit'
      if @actions?.die
        @setAction 'die'
      else
        @lifespan ?= Math.min(@lifespan, @world.dt)
    else
      # Hit something, but not an attackable thing--bounced off.
      # Box2D updates velocity/rotation; we effectively randomize the flyingHeight trajectory
      @bounced = true
      # Give the arrow velocity a random speed up or down depending on how fast it's going on the x, y plane
      @velocity.z += (@velocity.magnitude() / 4) * (1 - 2 * @world.rand.randf())
      #console.log @id, "bounced off of", thang.id, "at", @pos, thang.pos

  update: ->
    # We can't cancel collisions during beginContact or Box2D might get messed up
    justDied = not @dead and @action is 'die'
    hitGround = @isGrounded() and not @velocity.isZero(true)
    hitMeat = @collidedWith?
    if hitGround and @alwaysHits and not justDied
      @beginContact @alwaysHits
    if justDied or (@diesOnHit and hitGround)
      @setAction 'die'
      @act true
      @cancelCollisions()
      @addCurrentEvent 'die'
      @dead = true
      @updateRegistration()
      @lifespan ?= Math.min(@lifespan, 1.0)  # Play die animation for at most one second
      @velocity.multiply 0, true
    else if hitMeat  
      @setExists false
      @cancelCollisions()
      @destroyBody()
    else if hitGround
      # Ran out of range; lodge into the ground
      #console.log @shooter.id, @id, "lodged into the ground"
      if @acts
        @setAction 'die'
        @act true
      @velocity.multiply 0, true
      @body.SetAngularVelocity 0
      @cancelCollisions()
      @lifespan ?= Math.min(@lifespan, 1.0)  # Stick in ground for at most one second
Component = require 'lib/world/component'

{MAX_COOLDOWN} = require 'lib/world/systems/action'

# A floaty disc that bounces off obstacles until it bites into flesh!
module.exports = class RazorDisc extends Component
  @className: 'RazorDisc'

  attach: (thang) ->
    super thang
    if thang.acts
      thang.addActions name: 'die', cooldown: MAX_COOLDOWN

  launch: (shooter) ->
    # Assumes Missile launch has already been called, so we have @targetPos and @pos computed.
    @velocity.x = @targetPos.x - @pos.x
    @velocity.y = @targetPos.y - @pos.y
    @velocity.z = 0
    @velocity.normalize().multiply @maxSpeed

  maintainsElevation: -> true

  beginContact: (thang) ->
    return unless @exists
    #console.log @id, "beginContact", thang.id, thang.exists, thang.isAttackable, thang.health, @velocity.magnitude()
    hitMeat = thang.exists and thang.isAttackable and not @velocity.isZero(true)
    if hitMeat
      #console.log @shooter.id, @id, "hit", thang.id, "from", @id, "with velocity", @velocity, @velocity.magnitude(true)
      if @launchType is 'attack'
        @shooter.performAttackOriginal thang, 1
      else if @launchType is 'throw'
        @shooter.performThrownAttack thang, 1
      @velocity.multiply 0, true
      @collidedWith = thang
      @addCurrentEvent 'hit'
      if @actions?.die
        @setAction 'die'
      else
        @lifespan ?= Math.min(@lifespan, @world.dt)
    else
      # Hit something, but not an attackable thing--bounced off. Box2D updates velocity.
      @bounced = true
      #console.log @id, "bounced off of", thang.id, "at", @pos, thang.pos

  update: ->
    # We can't cancel collisions during beginContact or Box2D might get messed up
    justDied = not @dead and @action is 'die'
    hitMeat = @collidedWith?
    if justDied
      @setAction 'die'
      @act true
      @cancelCollisions()
      @addCurrentEvent 'die'
      @dead = true
      @updateRegistration()
      @lifespan ?= Math.min(@lifespan, @world.dt)
      @velocity.multiply 0, true
    else if hitMeat  
      @setExists false
      @cancelCollisions()
      @destroyBody()

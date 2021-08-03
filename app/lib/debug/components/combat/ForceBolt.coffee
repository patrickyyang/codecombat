Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{MAX_COOLDOWN} = require 'lib/world/systems/action'

module.exports = class ForceBolt extends Component
  @className: 'ForceBolt'

  attach: (thang) ->
    super thang
    #if thang.acts
    thang.addActions name: 'die', cooldown: MAX_COOLDOWN

  launch: (shooter, launchType) ->
    # Assumes Missile launch has already been called, so we have @targetPos and @pos computed.
    @launchType = launchType
    @velocity.x = @targetPos.x - @pos.x
    @velocity.y = @targetPos.y - @pos.y
    @velocity.z = @targetPos.z - @pos.z
    if @velocity.x is 0 and @velocity.y is 0
      @velocity = new Vector 1, 0, 0
    @velocity.normalize().multiply @maxSpeed
    @calculatedAttackDistance = @shooter[@launchType + 'Range'] ? @shooter.spells?[_.string.underscored(@launchType).replace(/_/g, '-')]?.range ? @velocity.magnitude()
    @rotation = @velocity.heading() % (2 * Math.PI)
    @thangsHit = []
    @hasRotated = true
    @launchPos = @pos.copy()
    if @spriteName is 'Plasma Ball'
      @pos.add @velocity.copy().limit(@shooter.width / 2 + @width / 2)

  beginContact: (thang) ->
    return unless @exists
    hitMeat = thang.exists and thang.isAttackable and not (thang.id in @thangsHit) and thang isnt @shooter
    hitMeat = false if @thangsHit.length and not @penetratesTargets
    if hitMeat
      @thangsHit.push thang.id
      if @launchType is 'forceBolt'
        @shooter.performForceBoltAttack thang
      else if @launchType is 'magicMissile'
        @shooter.performMagicMissileAttack thang
      else if @shooter.performAttackOriginal
        @shooter.performAttackOriginal thang, 1
      else
        console.log 'ForceBolt', @id, 'used for launchType', @launchType, '???'
    else
      # Hit something, but not an attackable thing--bounced off.
      null

  update: ->
    # We can't cancel collisions during beginContact or Box2D might get messed up
    if (not @shootsForever and @launchPos.distance(@pos) > @calculatedAttackDistance + 10 - @thangsHit.length) or (not @penetratesTargets and @thangsHit.length) or @velocity.magnitude() < 1 or @velocity.magnitude() > 1.2 * @maxSpeed
      @setAction 'die'
      @act true
      @cancelCollisions()
      @addCurrentEvent 'die'
      @dead = true
      @updateRegistration()
      @lifespan = Math.min(@lifespan ? 1.0, 1.0)  # Play die animation for at most one second
      @velocity.multiply 0, true

  maintainsElevation: ->
    true

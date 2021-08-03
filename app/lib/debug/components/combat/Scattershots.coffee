Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Scattershots extends Component
  @className: 'Scattershots'

  attach: (thang) ->
    scattershotAction = name: 'scattershot', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions scattershotAction

  scattershot: (targetOrPos) ->
    @intent = "scattershot"
    if not targetOrPos
      # No target or pos
      @setTargetPos new Vector(20, 0).rotate(@rotation).add @pos, 'scattershot' #Create a vector ->, rotate it by our rotation, add out position.
    else if targetOrPos.id?
      # Target has an id, so it is a thang
      @setTarget targetOrPos, 'scattershot'
    else if targetOrPos.pos?
      # Target has an pos
      @setTargetPos targetOrPos.pos, 'scattershot'
    else if targetOrPos.x? && targetOrPos.y?
      # Target is a positon
      @setTargetPos targetOrPos, 'scattershot'
    else if typeof targetOrPos is 'number'
      # Define distance player wants to shoot
      @setTargetPos new Vector(targetOrPos, 0).rotate(@rotation).add @pos, 'scattershot'
    else
      throw new ArgumentError "target isn't a unit or position.", "scattershot", "target", "object", targetOrPos
    
    if @actions.move and @distance(@target or @getTargetPos(), true) > @attackRange
      @setAction 'move'
    else
      @setAction 'scattershot'
    
    return @block?() unless @commander?

  update: ->
    return unless @intent is 'scattershot'
    if @action is 'move' and (@target? or @targetPos?)
      if @distance(@target or @getTargetPos(), true) <= @attackRange
        @setAction 'scattershot'
    return unless @action is 'scattershot' and @act()
    
    @unhide?() if @hidden
    targetPos = @getTargetPos() or new Vector(@attackRange, 0).rotate(@rotation).add(@pos)
    shotDistance = @distance targetPos
    dir = Vector.subtract(targetPos, @pos).normalize()
    if dir.isZero()
      console.log "Whoa no, got a zero vector difference when scattershooting! Let's just shoot to the right."
      dir = new Vector(1, 0)
    dir.multiply shotDistance
    for theta in [-@scattershotArcLength / 2 .. @scattershotArcLength / 2] by @scattershotArcLength / (@scattershotCount - 1)
      @setTargetPos Vector.add @pos, Vector.rotate(dir, theta)
      @targetPos.z = targetPos.z if targetPos?.z
      @performAttack()
      missile = @lastMissileShot
      missile.pos.add(Vector.normalize(missile.velocity, true).multiply(3, true), true)  # Start a little bit fanned out so that we can't hit our target a zillion times.
    
    @setAction 'idle'
    @setTarget null
    @unblock()
    @intent = undefined

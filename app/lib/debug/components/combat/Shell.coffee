Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{MAX_COOLDOWN} = require 'lib/world/systems/action'

# TODO: also bad name
module.exports = class Shell extends Component
  @className: "Shell"

  attach: (thang) ->
    super thang
    thang.addActions name: 'die', cooldown: MAX_COOLDOWN

  launch: (shooter, launchType='attack') ->
    # Assumes Missile launch has already been called
    # Ideally we would delay the actual Shell shot by a few frames to match the animation
    trajectory = Vector.subtract(@targetPos, @pos, true).limit @shooter[launchType + 'Range']
    trajectory.z += @depth / 2
    @targetPos = Vector.add @pos, trajectory, true  # Don't shoot out of range, and don't add track this modified targetPos with setTargetPos
    @flightTime = Math.ceil(@flightTime / @world.dt) * @world.dt + @world.dt * 2
    @velocity = Vector.divide trajectory, @flightTime, true
    # Adjust for gravity
    @velocity.z += @world.gravity * @flightTime / 2
    #@rotation = @trajectory.heading()  # We can only if the shell sprite is centered; also need @hasRotated = true if so
    #console.log @id, "launched from", @pos, "to", @targetPos, "along", trajectory, "with velocity", @velocity.toString(true)

  chooseAction: ->
    if @isGrounded() and not @exploded
      @explode()

  explode: ->
    combat = @world.getSystem("Combat")
    for thang in combat.attackables.concat(combat.corpses)
      continue if @team and not @friendlyFire and thang.team is @team
      enemyPos = thang.pos.copy()
      enemyPos.z -= thang.depth / 2
      v = Vector.subtract enemyPos, @pos, true
      d = v.magnitude false
      dWithZ = v.magnitude true
      continue unless d < @blastRadius
      damageRatio = (@blastRadius - d) / @blastRadius
      blastRatio = (@blastRadius - dWithZ) / @blastRadius
      momentum = v.copy().normalize(true).multiply blastRatio * @mass, true  # Could also add explosion momentum multiplier
      if thang.maintainsElevation?()
        momentum.z = 0
      if @stunDuration
        thang.addEffect? {name: 'paralyze', duration: @stunDuration * blastRatio, reverts: true, factor: 0.01, targetProperty: 'actionTimeFactor'}
      #console.log @id, "doing", damageRatio * @shooter[@launchType + 'Damage'], "to", thang.id, "with d", d, "of", @blastRadius
      if @launchType is 'attack'
        @shooter.performAttackOriginal thang, damageRatio, momentum
      else if @launchType is 'throw'
        @shooter.performThrownAttack thang, damageRatio, momentum
      else if @launchType is 'fireball'
        @shooter.performFireballAttack thang, damageRatio, momentum

    @addCurrentEvent 'hit'
    @velocity.multiply 0
    @exploded = true
    @setAction 'die'  # TODO: some sort of explode action might make more sense? 'die' being for combat system and all
    @act()

Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Slams extends Component
  @className: 'Slams'
  
  constructor: (config) ->
    super config
    @slamRangeSquared = @slamRange * @slamRange
    @slamImpulseRangeSquared = @slamImpulseRange * @slamImpulseRange
    @NORMALIZED_SLAM_Z = Math.sin(Math.PI / 8)  
    @fissureThangType = (@requiredThangTypes ? [])[0]
  
  attach: (thang) ->
    slamAction = {name: 'slam', cooldown: @cooldown, specificCooldown: @specificCooldown}
    delete @cooldown
    delete @specificCooldowm
    super thang
    thang.addActions slamAction
    thang.requiredThangTypes = (thang.requiredThangTypes ? []).concat(@requiredThangTypes ? [])
    thang.componentsForThangType @fissureThangType if @fissureThangType  # Make sure the Components are saved to the world's classMap.
    delete @requiredThangTypes
    
  configureFissure: ->
    if @fissureThangType
      @fissureComponents = _.cloneDeep @componentsForThangType @fissureThangType
      @fissureSpriteName = _.find(@world.thangTypes, original: @fissureThangType)?.name ? @fissureComponents
  
  makeFissure: () ->
    @configureFissure() unless @fissureComponents
    #console.log("TH", @fissureThangType
    fis = @spawn @fissureSpriteName, @fissureComponents
    fis.pos.x = @pos.x
    fis.pos.y = @pos.y
    # Assumes Missile launch has already been called
    diff = Vector.subtract(@target.pos, @pos)
    fis.width = @slamRange
    #@height = @width / 3.4375  # intended ratio of tesla beam width to height
    fis.height = 5.8181  # keep height constant regardless of shooting distance
    fisEnd = Vector.add(@pos, diff.copy().normalize().multiply(@slamRange))
    #collisionThangPos = @shooter.pos.copy().add new Vector(Math.cos(diff.heading()) * 0.5 * @width, Math.sin(diff.heading()) * 0.5 * @width)
    #@collisionThang = {shape: @shape, width: @width, height: @height, rotation: diff.heading(), pos: collisionThangPos}
    #shape = new {box: Rectangle, sheet: Rectangle, ellipsoid: Ellipse, disc: Ellipse}[@shape] @collisionThang.pos.x, @collisionThang.pos.y, @width, @height, @collisionThang.rotation
    #@collisionThang.getShape = -> shape
  
    # Now we adjust the visual properties of the beam.
    diff = Vector.subtract(fisEnd, @pos)
    #@width = diff.magnitude()
    fis.rotation = diff.heading()
    fis.pos.x += Math.cos(fis.rotation) * 0.5 * fis.width
    fis.pos.y += Math.sin(fis.rotation) * 0.5 * fis.width
    fis.pos.z = 0
    fis.scaleFactorX = fis.width / 16  # Beam image looks like it's 16m long.
    fis.scaleFactorX *= 1 - 0.25 * Math.abs(Math.sin(fis.rotation))
    #console.log @shooter.pos.toString(true), @pos.toString(true), @targetPos.toString(true), @rotation, @width, @height, @scaleFactorX
    fis.addTrackedProperties(["pos", "Vector"])
    fis.addTrackedProperties(["scaleFactorX", "number"])
    fis.addTrackedProperties(["rotation", "number"])
    fis.keepTrackedProperty 'pos'
    fis.keepTrackedProperty 'scaleFactorX'
    fis.keepTrackedProperty 'rotation'
    console.log(fis, fis.pos, fis.width, fis.height)
  
  slam: (target) ->
    unless target?
      throw new ArgumentError "Target is null. Is there always a target to slam? (Use if?)", "slam", "target", "object", target
    unless @bash?
      @sayWithoutBlocking? "Sla... Oh, I forgot my bash shield."
      return
    @slamMass = @bashMass * @slamMassCoefficient
    @setTarget target
    @intent = "slam"
    @block?()
  
  performSlam: () ->
    @unhide?() if @hidden
    @brake?()
    @makeFissure()
    @sayWithoutBlocking? "Slam!"
    targetDir = @target.pos.copy().subtract(@pos)
    @rotation = targetDir.heading()
    @target.takeDamage? @bashDamage, @, @getSlamMomentum(targetDir)
    for enemy in @findEnemies() when enemy isnt @target
      secondaryMomentum = @getSecondaryMomentum(targetDir, @target.pos, enemy.pos)
      enemy.takeDamage?(@bashDamage, @, secondaryMomentum) if secondaryMomentum

  getSlamMomentum: (dir) ->
    dir = dir.copy().normalize()
    dir.z = @NORMALIZED_SLAM_Z
    dir.multiply(@slamMass, true)
    return dir
    
  getSecondaryMomentum: (targetDir, targetPos, secondTargetPos) ->
    # TODO: Optimize this. Currently doing several vector algorithms repeatbly instead of in a row.
    secondTargetDir = secondTargetPos.copy().subtract(@pos)
    targetDirNorm = targetDir.copy().normalize()
    # Dot product check.
    vDot = secondTargetDir.dot(targetDirNorm, true);
    # Negative value means the secondTargetPos is behind the user's position.
    return if vDot < 0
    # Value over the magnitude of the distance to the enemy means they are past the enemy.
    # However, to give it a nice shape, we add an extra circular radius check (using the impulse range) so enemies around the target also get pushed.
    return if vDot > targetDir.magnitude() and targetPos.distanceSquared(secondTargetPos) > @slamImpulseRangeSquared
    # Vector rejection (perpendicular vector from targetDir to secondTargetDir)
    vRej = secondTargetDir.copy().subtract(secondTargetDir.copy().projectOnto(targetDirNorm, false));
    vRejMagnitude = vRej.magnitude()
    # If the scalar size of the rejection is greater than the radius of our impulse, ignore.
    return if vRejMagnitude > @slamImpulseRange
    # Normalize to direction
    dir = vRej.copy().normalize()
    # Set the standard flight angle
    dir.z = @NORMALIZED_SLAM_Z
    # Multiply the bashMass by the inverse magnitude of the vRej, with the radius of our impulse being the maximum range to hit with Slam.
    dir.multiply((@slamMass * (1 - vRejMagnitude / @slamImpulseRange)), true)
    return dir
    
  update: (target) ->
    return unless @intent is "slam"
    unless @target or @target.health? <= 0
      @intent = null
      @setAction "idle"
      @unblock?()
      return
    if @distanceSquared(@target) > @slamRangeSquared
      @setAction "move"
    else
      @setAction "slam"
    if @action is "slam" and @act()
      @unblock?()
      @performSlam()
      @setAction("idle")

    
  ###
  bash: (target) ->
    unless target?
      throw new ArgumentError "Target is null. Is there always a target to bash? (Use if?)", "bash", "target", "object", target
      
    @setTarget target, 'bash'
    return "done" unless @target  # If Naria's hide ability has nulled out our target while we were chasing, we are done.

    if @actions.move and @distance(@target, true) > @bashRange
      @setAction 'move'
    else
      @setAction 'bash'
    if @distance(@target, true) <= @bashRange and @getCooldown('bash') > 1  # TODO: test only doing this after one frame, so that we don't infinitely loop?
      "done"
    else if @bashedOnce or @target?.health <= 0
      @bashedOnce = false
      @setAction 'idle'
      "done"
    else
      "bash"

  getBashMomentum: (targetPos) ->
    dir = targetPos.copy().subtract(@pos).normalize()
    dir.z = Math.sin Math.PI / 8
    dir.multiply @bashMass, true
    dir

  update: ->
    return unless @action is 'bash' and @target and @distance(@target, true) <= @bashRange and @act()
    @say? 'Bash!'
    @rotation = Vector.subtract(@target.pos, @pos).heading()  # Face target
    momentum = @getBashMomentum(@target.pos)
    @target.takeDamage? @bashDamage, @, momentum
    @brake?()
    @unhide?() if @hidden
    @bashedOnce = true if @plan
  ###
  
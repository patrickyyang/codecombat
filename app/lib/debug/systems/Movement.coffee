System = require 'lib/world/system'
{WATER_DENSITY, AIR_DENSITY, VACUUM_DENSITY, SWAMP_DENSITY, STANDARD_FRICTION, ICE_FRICTION} = require 'lib/world/systems/movement'
Vector = require 'lib/world/vector'

# Action before Movement before Collision

module.exports = class Movement extends System
  constructor: (world, config) ->
    super world, config
    @world.gravity = @gravity ?= 9.81  # m / s^2 ya
    @movers = @addRegistry (thang) -> thang.isMovable and thang.exists
    @lands = @addRegistry (thang) -> thang.isLand and thang.exists
    @gravityFields = []
    @frictionFields = []
    @magneticFields = []

  update: ->
    # Optimize...
    hash = 0
    # We'd have to update this optimizeLands check if we wanted to make friction work better than all-or-nothing.
    optimizeLands = _.all(@lands, (land) -> land.friction and land.airDensity is AIR_DENSITY) and not @frictionFields.length
    if optimizeLands
      # Simplify the computation, since there's nothing interesting going on.
      for mover in @movers
        @updateMotion mover, currentLand
    else
      for mover in @movers
        currentLand = null
        for land in @lands  # ordered by which land was created first...
          if land.contains? mover
            currentLand = land
            break
        @updateMotion mover, currentLand
        # If you want this entered/left map stuff to work, set one of the lands to have non-standard airDensity so optimizeLands is false.
        if currentLand and not mover.isWithinMap
          mover.publishNote 'thang-entered-map', {}
        else if not currentLand and mover.isWithinMap
          mover.publishNote 'thang-left-map', {}
        mover.isWithinMap = Boolean currentLand
      hash += (mover.pos.x - mover.pos.y - mover.pos.z) * @world.age
    @updateFields()
    hash

  updateMotion: (mover, land) ->
    # To optimize...
    landDensity = if land then land.airDensity else AIR_DENSITY
    landFriction = if land then land.friction else STANDARD_FRICTION
    if land and mover.isGrounded()
      landDensity += land.groundDensity
      if @frictionFields.length
        landFriction = @frictionAt mover.pos, landFriction
    else if mover.isAirborne()
      landFriction = 0
  
    # Ideally these forces would affect velocity before it affected position, but locomote() needs to know exactly how much to accelerate to hit maxSpeed.
    fRR = mover.calculateRollingResistance landDensity, landFriction, mover.velocity
    fDrag = mover.calculateDrag landDensity, mover.velocity
    mover.velocity.add(Vector.multiply(Vector.add(fRR, fDrag), @world.dt / mover.mass).limit(mover.velocity.magnitude()))
  
    airborne = mover.isAirborne() or mover.velocity.z > 0
    if (airborne or @hasGravitationalAnomalies) and not mover.maintainsElevation?()
      if @hasGravitationalAnomalies
        gravity = @gravityAt mover.pos
      else
        gravity = @world.gravity
      mover.velocity.z = Math.max 0, mover.velocity.z unless airborne
      if airborne or gravity < 0
        mover.velocity.z -= gravity * @world.dt
        mover.pos.z = Math.max(mover.depth / 2, mover.pos.z + mover.velocity.z * @world.dt)
        mover.hasMoved = true
        #console.log "Moved", mover, "to", mover.pos.z, "with vz", mover.velocity.z, 'from gravity', gravity if mover.id is 'Joan'

    if (mover.action is "move" or mover.action is "flee") and mover.act()
      fLocomotion = mover.locomote()
      mover.unblock?() unless (mover.multiFrameMove or mover.intent?)
      if fLocomotion and not fLocomotion.isZero()
        if landFriction is 0 and mover.locomotionType isnt 'flying'
          fLocomotion.multiply 0
        #console.log mover.id, "got locomotion:", fLocomotion, "pos:", mover.pos, "target:", mover.targetPos ? mover.target?.pos, "v:", mover.velocity
        if false
          # Limit fLocomotion to only the amount of force which the Thang should physically be able to generate
          originalLocomotiveMagnitude = fLocomotion.magnitude()
          switch mover.locomotionType
            # Problem: sometimes the Thangs aren't heavy enough to apply as much force as we want. Hack it?
            when "rolling" then fLocomotion.limit landFriction * mover.mass * @world.gravity * 5  # Hack
            when "running" then fLocomotion.limit landFriction * mover.mass * @world.gravity * 5  # Hack
            when "flying" then fLocomotion.multiply landDensity / AIR_DENSITY
            when "swimming" then fLocomotion.multiply landDensity / WATER_DENSITY
          limitedLocomotiveMagnitude = fLocomotion.magnitude()
          if limitedLocomotiveMagnitude < originalLocomotiveMagnitude
            console.log "Hmm;", @id, "was limited from", originalLocomotiveMagnitude, "to", limitedLocomotiveMagnitude, "at velocity:", mover.velocity, "friction:", landFriction, "mass:", mover.mass, "density:", landDensity
        mover.velocity.add(Vector.multiply fLocomotion, @world.dt / mover.mass)
    else if (mover.action is "move" or mover.action is "flee") and mover.actionHeats.all and mover.locomotiveForce and mover.actions.move.cooldown
      mover.velocity.add(Vector.multiply mover.locomotiveForce, @world.dt / mover.mass)
    if @hasMagneticAnomalies and mover.act? and not mover.nonferrous
      mover.velocity.x = mover.velocity.y = 0
      mover.velocity.add(@magneticForceAt(mover.pos))
    # We used to do this just once at the end, but can't now that the world streaming is happening.
    # In the case where a Thang moves/rotates but ceases to exist on the same frame... guess it wouldn't matter.
    if not mover.hasTrackedPos and mover.hasMoved
      mover.keepTrackedProperty 'pos'
      mover.keepTrackedProperty 'velocity'
      mover.hasTrackedPos = true
    if not mover.hasTrackedRotation and mover.hasRotated
      mover.keepTrackedProperty 'rotation'
      mover.hasTrackedRotation = true
  
    # position update is done in the Collision System

  addGravityField: (field) ->
    @addField @gravityFields, field
    @hasGravitationalAnomalies = true

  addFrictionField: (field) ->
    @addField @frictionFields, field
  
  addMagneticField: (field) ->
    @addField @magneticFields, field
    @hasMagneticAnomalies = true

  addField: (fields, field) ->
    field.pos.z = 0
    fields.push field

  updateFields: ->
    for [fieldType, color] in [['gravity', 'rgba(89, 63, 115, 0.15)'], ['friction', 'rgba(165, 242, 243, 0.15)'], ['magnetic', 'rgba(240, 220, 40, 0.1)']]
      fields = @[fieldType + 'Fields']
      for field in fields
        field.duration -= @world.dt
        if field.source?.addCurrentEvent
          args = [parseFloat(field.pos.x.toFixed(2)), parseFloat(field.pos.y.toFixed(2)), parseFloat(field.radius.toFixed(2)), color]
          field.source.addCurrentEvent "aoe-#{JSON.stringify(args)}"
      @[fieldType + 'Fields'] = (field for field in fields when field.duration > 0)
    @hasGravitationalAnomalies = false unless @gravityFields.length
    @hasMagneticAnomalies = false unless @magneticFields.length

  gravityAt: (pos) ->
    return @gravity unless @gravityFields.length
    inField = false
    gravity = @world.gravity
    for field in @gravityFields
      distance = pos.distance field.pos
      strength = Math.min 1, (field.radius - distance) / field.radius
      continue unless strength > 0
      unless inField
        inField = true
        gravity = 0
      gravity += (if field.attenuates then strength else 1) * field.gravity
    gravity

  frictionAt: (pos, normalFriction) ->
    return normalFriction unless @frictionFields.length
    inField = false
    friction = @world.friction
    for field in @frictionFields
      continue unless pos.distanceSquared(field.pos) <= field.radius * field.radius
      unless inField
        inField = true
        friction = 0
      friction += field.friction
    friction
    
  magneticForceAt: (pos) ->
    return 0 unless @magneticFields.length
    inField = false
    magneticForce = new Vector(0, 0)
    for field in @magneticFields
      # TODO: Add distance check to verify we're in range
      unless inField
        inField = true
        magneticForce = new Vector(0, 0)
      magneticForce.subtract(Vector.subtract(pos, field.pos).normalize()).multiply(field.force)
    magneticForce

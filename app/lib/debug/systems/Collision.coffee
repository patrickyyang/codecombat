System = require 'lib/world/system'
box2d = require 'lib/world/box2d'
#{CollisionCategory} = require 'lib/world/systems/collision'

class CollisionCategory
  @className: 'CollisionCategory'
  constructor: (name, @superteamIndex=null, @collisionSystem) ->
    # @superteamIndex is null for 'none', 'obstacles', and 'dead'.
    # It's 0 for 'ground', 'air', and 'ground_and_air' units with no superteams.
    # It's 1, 2, or 3 for the superteams it gets after that. We can only have 16 collision categories.
    @ground = name.search('ground') isnt -1
    @air = name.search('air') isnt -1
    @name = CollisionCategory.nameFor name, @superteamIndex
    @superteamIndex ?= 0 if @ground or @air
    @number = 1 << @collisionSystem.totalCategories++
    if @collisionSystem.totalCategories > 16 then console.log 'There should only be 16 collision categories!'
    @mask = 0
    @collisionSystem.allCategories[@name] = @
    for otherCatName, otherCat of @collisionSystem.allCategories
      if @collidesWith otherCat
        @mask = @mask | otherCat.number
        otherCat.mask = otherCat.mask | @number

  collidesWith: (cat) ->
    # 'none' collides with nothing
    return false if @name is 'none' or cat.name is 'none'

    # 'obstacles' collides with everything; could also try letting air units (but not ground_and_air) fly over these
    return true if cat.name is 'obstacles' or @name is 'obstacles'

    # 'dead' collides only with obstacles
    return cat.name is 'obstacles' if @name is 'dead'
    return @name is 'obstacles' if cat.name is 'dead'
    
    # 'pet' collides only with obstacles and ground (air_and_ground too) thangs which has superteamIndex 0 (non-allied thangs)
    return cat.name is'obstacles' or (not cat.superteamIndex and cat.ground and not cat.air) if @name is 'pet'
    return @name is'obstacles' or (not @superteamIndex and @ground and not @air) if cat.name is 'pet'

    # 'ground_and_air_<team>' units don't hit ground or air units on their team (so missiles don't hit same team)
    sameTeam = @superteamIndex and cat.superteamIndex is @superteamIndex
    return false if sameTeam and @ground and @air

    # actually, 'ground_and_air<team>' units don't hit any ground_and_air units (temp missile collision fix)
    return false if @ground and @air and cat.ground and cat.air

    # 'ground' collides with 'ground'
    return true if cat.ground and @ground

    # 'air' collides with 'air'
    return true if cat.air and @air

    # doesn't collide (probably 'ground' and 'air')
    false
  
  @nameFor: (name, superteamIndex=null) ->
    return name unless name.match('ground') or name.match('air')
    name + '_' + (superteamIndex or 0)
  

module.exports = class Collision extends System
  nanVelocityCount: 0

  constructor: (world, config) ->
    super world, config
    @colliders = @addRegistry (thang) -> thang.collides and (thang.isMovable or thang.collisionCategory isnt 'none' or thang.isHazard)
    @extantColliders = @addRegistry (thang) -> thang.collides and thang.exists and (thang.isMovable or thang.collisionCategory isnt 'none' or thang.isHazard)
    @initializeCollisionCategories()
    return unless box2d?
    @box2dWorld = new box2d.b2World(new box2d.b2Vec2(0, 0), true)
    @contactListener = new box2d.b2ContactListener()
    @contactListener.BeginContact = (contact) ->
      t1 = contact.GetFixtureA().GetBody().GetUserData()
      t2 = contact.GetFixtureB().GetBody().GetUserData()
      t1.beginContact?(t2)
      t2.beginContact?(t1)
    #@contactListener.EndContact = (contact) ->
      #console.log "EndContact"
    @contactListener.PreSolve = (contact, oldManifold) ->
      t1 = contact.GetFixtureA().GetBody().GetUserData()
      t2 = contact.GetFixtureB().GetBody().GetUserData()
      # collidedWith: for things that can only collide with one other target (arrows)
      # don't think this works
      if t1.type is 'plasma-ball' and t2.type is 'plasma-ball'
        contact.SetEnabled false
        return
      alreadyCollided = t1.collidedWith is t2 or t2.collidedWith is t1
      if not alreadyCollided
        collidedWithOther = t1.collidedWidth? or t2.collidedWidth?
        if collidedWithOther
          contact.SetEnabled false
    #@contactListener.PostSolve = (contact, impulse) ->
      #console.log "There was a collision", impulse.normalImpulses
    @box2dWorld.SetContactListener @contactListener

  initializeCollisionCategories: ->
    @superteams = [null]  # mapping from superteams to superteam indices
    @totalCategories = 0
    @allCategories = {}
    new CollisionCategory(cat, null, @) for cat in ["none", "obstacles", "dead", "pet"]
    for superteamIndex in [0 .. 3]  # up to 3 superteams
      for cat in ["ground", "air", "ground_and_air"]
        new CollisionCategory cat, superteamIndex, @
    
  nameFor: (name, superteamIndex=null) ->
    CollisionCategory.nameFor(name, superteamIndex)
  
        
  start: (thangs) ->
    @update false

  update: (advance=true) ->
    # Optimize!
    return 0 unless box2d?
    for thang in @colliders
      body = thang.body
      body.SetActive thang.exists if body  # This already checks whether active has changed
      continue unless thang.exists
      continue unless thang.pos
      body ?= thang.createBody()
      currentPos = body.GetPosition()
      currentAngle = body.GetAngle()
      if Math.abs(currentPos.x - thang.pos.x) > 0.0000001 or Math.abs(currentPos.y - thang.pos.y) > 0.0000001 or (not thang.fixedRotation and currentAngle isnt thang.rotation)
        # This operation is expensive because it recalculates the transform and does all sorts of other things, and usually isn't needed, so we'll skip
        body.SetPositionAndAngle(new box2d.b2Vec2(thang.pos.x, thang.pos.y), if thang.fixedRotation then body.GetAngle() else thang.rotation)
      if thang.velocity
        
        if _.isNaN(thang.velocity.x) or _.isNaN(thang.velocity.y)
          thang.velocity.x = 0 if _.isNaN thang.velocity.x
          thang.velocity.y = 0 if _.isNaN thang.velocity.y
          ++@nanVelocityCount
          if @nanVelocityCount > 10
            # Recovery didn't work (does it ever?)
            console.log '-------- Aborting simulation due to NaN velocities corrupting collision system. (Internal CodeCombat coding error.) --------'
            @world.endWorld false, 0
        body.SetLinearVelocity new box2d.b2Vec2(thang.velocity.x, thang.velocity.y)
        
        if thang.velocity.x or thang.velocity.y
          body.SetAwake true
    return unless advance

    # Can change these values to change precision/speed; 8, 3 were recommended. Even as low as 1, 1 or high as 100, 100 had no visible effect on runtime of complex world (but 10000, 10000 did)
    @box2dWorld.Step @world.dt, 8, 3
    @box2dWorld.ClearForces()

    for thang in @extantColliders
      body = thang.body
      unless thang.fixedRotation or thang.action is 'attack'
        newRotation = body.GetAngle()
        if newRotation isnt thang.rotation
          thang.rotation = newRotation
          thang.hasRotated = true
      newPos = body.GetPosition()
      if Math.abs(newPos.x - thang.pos.x) > 0.0000001 or Math.abs(newPos.y - thang.pos.y) > 0.0000001
        [thang.pos.x, thang.pos.y] = [newPos.x, newPos.y]
        thang.hasMoved = true
        # To remove delay for sticked thangs
        if thang.hasSticked
          thang.hasSticked.updateSticked?()
        # Moved once handled in movement.Moves component
        thang.movedOnce = true if thang.movedOncePos? and thang.movedOncePos is thang.targetPos
      if thang.velocity
        newVelocity = body.GetLinearVelocity()
        [thang.velocity.x, thang.velocity.y] = [newVelocity.x, newVelocity.y]
    hash = 0

  finish: (thangs) ->
    # Somehow this might not be enough–somehow b2Worlds stick around sometimes in the b2World class's internal state?
    thang.destroyBody() for thang in @colliders
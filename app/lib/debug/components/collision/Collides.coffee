Component = require 'lib/world/component'

box2d = require 'lib/world/box2d'
#{CollisionCategory} = require 'lib/world/systems/collision'

module.exports = class Collides extends Component
  @className: "Collides"
  collides: true

  # Override @bodyDef.type, @bodyDef.bullet, @bodyDef.fixedRotation,
  # @fixDef.filter.categoryBits, or @fixDef.filter.maskBits before first frame only.
  updateCollisionFilterBits: (filter, catName) ->
    st = @superteam ? null
    @collisionSystem = @world.getSystem("Collision")
    superteams = @collisionSystem.superteams
    if st in superteams
      superteamIndex = superteams.indexOf st
    else
      superteamIndex = superteams.push(st) - 1
    cat = @collisionSystem.allCategories[@collisionSystem.nameFor catName or @collisionCategory, superteamIndex]
    @collisionCategory = catName
    filter.categoryBits = cat.number
    filter.maskBits = cat.mask

  attach: (thang) ->
    super thang
    thang.createBodyDef()
    thang.createBody() if thang.exists and (thang.moves or thang.collisionCategory isnt 'none')
    thang.originalCollisionCategory = thang.collisionCategory

  createBodyDef: ->
    return unless box2d? and window.BOX2D_ENABLED isnt false
    bodyDef = new box2d.b2BodyDef()
    [bodyDef.position.x, bodyDef.position.y] = [@pos.x, @pos.y]
    bodyDef.type = switch @collisionType
      when "static" then box2d.b2Body.b2_staticBody
      when "kinematic" then box2d.b2Body.b2_kinematicBody
      when "dynamic" then box2d.b2Body.b2_dynamicBody
    bodyDef.bullet = @isBullet
    bodyDef.fixedRotation = @fixedRotation
    bodyDef.active = @exists
    fixDef = new box2d.b2FixtureDef()
    @updateCollisionFilterBits fixDef.filter, @collisionCategory
    fixDef.friction = 0.0  # what? (?)
    fixDef.restitution = @restitution
    area = 0
    switch @shape
      when "ellipsoid", "disc"
        # Box2D doesn't have ellipses!
        diameter = Math.max(@width, @height)
        if (Math.abs(@width - @height) / diameter) <= 0.25
          # Almost circular; approximate with a circle with r according to major axis.
          radius = diameter / 2
          fixDef.shape = new box2d.b2CircleShape radius
          area = Math.PI * radius * radius
        else
          # Not so circular; approximate with a polygon.
          segmentCount = 16
          segmentLength = 2 * Math.PI / segmentCount
          [w2, h2] = [@width / 2, @height / 2]
          vertices = []
          for theta in [0 ... segmentCount]
            vertices.push new box2d.b2Vec2(w2 * Math.cos(segmentLength * theta), h2 * Math.sin(segmentLength * theta))
          fixDef.shape = box2d.b2PolygonShape.AsArray vertices, segmentCount
          area = Math.PI * w2 * h2
      when "box", "sheet"
        fixDef.shape = box2d.b2PolygonShape.AsBox @width / 2, @height / 2
        area = @width * @height
    fixDef.density = @mass / area  # make sure mass is set how we want
    #console.log @id, "got density", fixDef.density, "from", @mass, area, "with shape", @shape, "width", @width, "height", @height
    #if @spriteName is "Arrow" then fixDef.density *= 100  # testing arrow knockback
    @bodyDef = bodyDef
    @fixDef = fixDef

  cancelCollisions: (becauseOfDeath=false, alternativeCategory=null) ->
    return unless @body
    # Have to twiddle @body.SetActive or it doesn't take effect
    @body.SetActive false
    fixtureList = @body.GetFixtureList() 
    filterData = fixtureList.GetFilterData()
    becauseOfDeath = becauseOfDeath and @collisionType is "dynamic"
    catName = @collisionSystem.nameFor if becauseOfDeath then "dead" else (alternativeCategory or "none")
    @updateCollisionFilterBits filterData, catName
    @body.SetActive true if becauseOfDeath  # So we can still collide with obstacles
    @body.GetFixtureList().SetFilterData filterData
    @updateRegistration() unless becauseOfDeath  # Don't bother doing for death, dead Thangs will probably reregister anyway
    
  restoreCollisions: ->
    return unless @body
    # Might have to twiddle @body.SetActive or it doesn't take effect
    @body.SetActive false
    fixtureList = @body.GetFixtureList() 
    filterData = fixtureList.GetFilterData()
    @updateCollisionFilterBits filterData, @originalCollisionCategory
    @body.SetActive true
    @body.GetFixtureList().SetFilterData filterData

  createBody: ->
    return if @body
    return unless box2dWorld = @world.getSystem('Collision')?.box2dWorld
    @body = box2dWorld.CreateBody @bodyDef
    @body.SetUserData @
    @body.CreateFixture @fixDef
    @body.SetAngle @rotation if @rotation
    @body

  destroyBody: ->
    return unless @body
    @body.SetUserData null
    @world.getSystem("Collision").box2dWorld.DestroyBody @body
    @body = @bodyDef = @fixDef = null
  
  beginContact: (thang) ->
    if @eventHandlers?.collide?.length > 0
      @trigger? "collide", {target: @, other: thang}
        
        
        
        
        
        
  
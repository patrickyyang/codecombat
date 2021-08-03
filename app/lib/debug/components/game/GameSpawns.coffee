Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class GameSpawns extends Component
  @className: 'GameSpawns'

  initialize: ->
    @AI ?= {}
    @AI["AttacksNearest"] = @AIAttacksNearest
    @AI["FearsTheLight"] = @AIFearsTheLight
    @AI["RunsAway"] = @AIRunsAway
    @AI["Scampers"] = @AIScampers
    @AI["Defends"] = @AIDefends
    @AI["Collects"] = @AICollects
    @_propertyHelpers = []
    @registerPropertyHelper(@attachScaleHelper)
    @registerPropertyHelper(@attachBehaviorHelper)
    @registerPropertyHelper(@attachVisibleHelper)
    @registerPropertyHelper(@attachAttackableHelper)
    @registerPropertyHelper(@attachMovableHelper)
    @registerPropertyHelper(@attachMaxSpeedHelper)
    @registerPropertyHelper(@attachCollectsHelper)
    @registerPropertyHelper(@attachAttackCooldownHelper)
    @esperProperties = ["scale", "visible", "behavior", "attackable", "movable", "collects", "maxSpeed"]
    
  registerPropertyHelper: (helper) ->
    if not (helper in @_propertyHelpers)
      @_propertyHelpers.push(helper) 

  attachAI: (thang, str) ->
    return unless thang and str
    return unless @AI[str]
    thang.AIHandler = thang.on 'update', @AI[str]

  attachPropertyHelpers: (thang) ->
    fn(thang) for fn in @_propertyHelpers

  attachBehaviorHelper: (thang) ->
    if thang.isAttackable or thang.isMovable
      Object.defineProperty(thang, "esper_behavior", {
        enumerable: true,
        get: () -> thang.behavior,
        set: (x) ->
          return if x is undefined
          game = thang.commander
          unless _.isString(x) and x in _.keys(game.AI)
            throw new Error "behavior must be set to one of: #{_.keys(game.AI).join(', ')}"
            
          thang.keepTrackedProperty 'behavior'
          thang.behavior = x
          # Doesn't make sense to allow multiple behaviors when set this way.
          # If you know to call attachAI directly, you're on your own :)
          thang.off('update', thang.AIHandler) if thang.AIHandler
          game.attachAI thang, x
          game.attachAI thang, "FearsTheLight" if thang.spriteName is 'Skeleton' and x isnt 'FearsTheLight'
      })

  attachScaleHelper: (thang) ->
    Object.defineProperty(thang, "esper_scale", {
      enumerable: true,
      get: () -> thang.scaleFactor,
      set: (x) ->
        return unless _.isNumber(x)
        thang.keepTrackedProperty "scaleFactor"
        prevScaleFactor = thang.scaleFactor or 1
        thang.ignorePropertyTypoChecks = true
        thang.scaleFactor = x
        thang.ignorePropertyTypoChecks = false
        if thang.collides and thang.collisionCategory isnt "none" and thang.exists
          scaleK = x / prevScaleFactor
          thang.height *= scaleK
          thang.width *= scaleK
          thang.destroyBody?()
          thang.createBodyDef?()
          thang.createBody?()
          thang.updateRegistration?()
    })
    
  attachVisibleHelper: (thang) ->
    Object.defineProperty(thang, "esper_visible", {
      enumerable: true,
      get: () -> thang.alpha isnt 0,
      set: (isVisible) ->
        return if not thang?
        if not thang.alpha?
          thang.addTrackedProperties ["alpha", "number"]
        thang.alpha = if isVisible then 1 else 0
        if not isVisible
          thang.isAttackable = false
        # thang.keepTrackedProperty("alpha")
      })
  
  attachAttackableHelper: (thang) ->
    Object.defineProperty(thang, "esper_attackable", {
      enumerable: true,
      get: () -> thang.isAttackable,
      set: (isAttackable) ->
        return if not thang?
        if thang.isAttackable is undefined
          return # TODO??? non-attackable thangs need Die animation.
        thang.isAttackable = isAttackable
      })
      
  attachMovableHelper: (thang) ->
    world = thang.world
    Object.defineProperty(thang, "esper_movable", {
      enumerable: true,
      get: () -> thang.isMovable,
      set: (isMovable) ->
        return unless isMovable?
        return if not thang or not thang.id # sometimes we get weird cut thang
        return unless thang.components
        if thang.isMovable is undefined
          components = []
          if not _.find(thang.components, (component) -> component?[0].className is 'Collides') and world.classMap['Collides']
            components.push([world.classMap['Collides'], {
              collisionCategory: "none",
              collisionType: "dynamic",
              mass: 70
              }])
          if not _.find(thang.components, (component) -> component?[0].className is 'Acts') and world.classMap['Acts']
            components.push([world.classMap['Acts'], {resetToIdle: false}])
          if not _.find(thang.components, (component) -> component?[0].className is 'Targets') and world.classMap['Targets']
            components.push([world.classMap['Targets'], {}])
          if not _.find(thang.components, (component) -> component?[0].className is 'Moves') and world.classMap['Moves']
            components.push([world.classMap['Moves'], {
              cooldown: 0,
              currentSpeedRatio: 1,
              dragCoefficient: 1,
              locomotionType: "running",
              maxAcceleration: 100,
              maxSpeed: 12,
              rollingResistance: 0.3
              }])
            
          if components.length
            thang.addComponents(components...)
            thang.velocity = new Vector(0, 0, 0);
            thang.collisionType = "dynamic"
            thang.destroyBody?()
            thang.createBodyDef?()
            thang.createBody?()
            thang.updateRegistration()
        thang.isMovable = isMovable
        if not isMovable
          thang.prevMaxSpeed = thang.maxSpeed
          thang.maxSpeed = 0
        if thang.prevMaxSpeed and isMovable
          thang.prevMaxSpeed = null
          thang.maxSpeed = thang.prevMaxSpeed
      })
  
  attachMaxSpeedHelper: (thang) ->
    Object.defineProperty(thang, "esper_maxSpeed", {
      enumerable: true,
      get: () -> thang.maxSpeed,
      set: (speed) ->
        if speed > 0
          thang.esper_movable = true
        thang.maxSpeed = speed
    })
   
  attachCollectsHelper: (thang) ->
    world = thang.world
    Object.defineProperty(thang, "esper_collects", {
      enumerable: true,
      get: () -> thang.autoCollects,
      set: (collects) ->
        return unless collects?
        return if not thang or not thang.id # sometimes we get weird cut thang
        return unless thang.components
        if thang.autoCollects is undefined
          components = []
          if not _.find(thang.components, (component) -> component?[0].className is 'Collects') and world.classMap['Collects']
            components.push([world.classMap['Collects'], {
              autoCollects: true,
              collectRange: 5
              }])
          if components.length
            thang.addComponents(components...)
        i = world.getSystem("Inventory")
        thang.autoCollects = collects
        
        thang.updateRegistration()
      })
  
  attachAttackCooldownHelper: (thang) ->
    Object.defineProperty(thang, "esper_attackCooldown", {
      enumerable: true,
      get: () -> thang.actions?.attack?.cooldown,
      set: (cooldown) ->
        if thang.actions?.attack?.cooldown?
          thang.actions?.attack?.cooldown = cooldown
    })
  
  attachMethodHelpers: (thang) ->
    # "defeat" method for players
    if thang.isAttackable
      thang.esper_defeat = () ->
        return if @dead or @health <= 0
        @die?()
    # "destroy" alias for setExists for players
    thang.esper_destroy = () ->
      return unless @
      return if @destructable? and @destructable is false
      if @id is 'Hero Placeholder'
        throw new Error "Don't call `game.destroy()`! Call `unit.destroy()` for some unit."
      @setExists?(false)

  AIAttacksNearest: (e) ->
    return unless self = e.target
    enemy = self.getNearestEnemy?()
    if enemy and not self.fleeingFrom?.hasActiveLightstone
      self.attack? enemy

  AIRunsAway: (e) ->
    return unless self = e.target
    enemies = self.findEnemies?() ? []
    moveTo = self.pos.copy()
    for enemy in enemies when enemy.distance(self) < Math.max(14, enemy.attackRange)
      moveVector = self.pos.copy().subtract(enemy.pos).normalize().multiply(5)
      moveTo = moveTo.add moveVector
    self.move moveTo

      
  AIFearsTheLight: (e) ->
    return unless self = e.target
    enemies = self.findEnemies?() ? []
    for enemy in enemies when enemy.distance(self) < 14
      continue unless light = enemy.hasActiveLightstone
      range = light.lightstoneRange ? 14
      if self.distance(enemy) < range
        self.fleeingFrom = enemy
        moveVector = self.pos.copy().subtract(enemy.pos).normalize().multiply(5)
        self.move self.pos.copy().add(moveVector)

  AIScampers: (e) ->
    return unless self = e.target
    return if self.dead
    return if self.action is 'move' and self.targetPos and self.distance(self.targetPos) > 2
    world = self.world
    game = self.commander
    angle = world.rand.randf() * 2 * Math.PI
    game.aiSystem ?= world.getSystem("AI")
    grid = game.aiSystem.getNavGrid()
    distance = 1
    maxDistance = 15 + world.rand.randf() * 15
    until distance > maxDistance or grid.contents(self.pos.x + Math.cos(angle) * distance, self.pos.y + Math.sin(angle) * distance).length
      distance += 0.5
    if distance > 1
      self.move new Vector(self.pos.x + Math.cos(angle) * distance, self.pos.y + Math.sin(angle) * distance)
  
  AICollects: (e) ->
    return unless self = e.target
    return if self.dead
    item = self.findNearestItem?()
    if item?.pos
      self.move?(item.pos)
  
  AIDefends: (e) ->
    return unless self = e.target
    self.defendPos ?= self.pos.copy()
    enemy = self.findNearestEnemy?()
    if enemy and self.distance(enemy) < self.attackRange and self.distance(self.defendPos) < 3
      self.attack? enemy
    else
      self.move self.defendPos
    
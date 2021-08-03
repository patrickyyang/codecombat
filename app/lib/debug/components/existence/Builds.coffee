Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Builds extends Component
  @className: 'Builds'
  constructor: (config) ->
    super config
    @unitNames = @buildTypes = []  # unitNames: old compabitility copy
    @built = []
    @_buildables = @buildables ? {}
    delete @buildables

  attach: (thang) ->
    super thang
    thang.addActions {name: 'build'} if thang.acts
    thang.addTrackedProperties ['built', 'array']
    thang.inventorySystem = thang.world.getSystem("Inventory")
    thang.addBuildable buildType, buildable for buildType, buildable of @_buildables
    
  addBuildable: (buildType, buildable) ->
    @buildables ?= {}
    oldBuildable = @buildables[buildType]
    return if oldBuildable and ((oldBuildable.goldCost or 0) < (buildable.goldCost or 0))
    return if oldBuildable and ((oldBuildable.goldCost or 0) is (buildable.goldCost or 0) and oldBuildable.buildCooldown <= buildable.buildCooldown)
    @buildables[buildType] = buildable
    buildable.type = buildType
    @buildTypes.push buildType unless buildType in @buildTypes

  build: (toBuild) ->
    # Provide build() in non-plannable, old levels. It doesn't work with plan.
    if typeof toBuild is 'undefined'
      throw new ArgumentError "You need something to build.", "build", "toBuild", "object", toBuild
    unless toBuild in @buildTypes
      throw new ArgumentError "You need a string to build; one of [\"#{@buildTypes.join('\", \"')}\"]", "build", "toBuild", "object", toBuild
    toBuild = @buildables[toBuild]
    @actions.build.cooldown = toBuild.buildCooldown
    @setAction 'build'
    @toBuild = toBuild
    @targetPos = null
    @toBuild  # Return what we are trying to build.

  buildXY: (toBuild, x, y) ->
    # Provide buildXY() in plannable, hero levels. It works with plan, but doesn't return the build template.
    if not _.isNumber x
      throw new ArgumentError "Build the #{toBuild} at an (x, y) coordinate.", "buildXY", "x", "number", x
    if not _.isNumber y
      throw new ArgumentError "Build the #{toBuild} at an (x, y) coordinate.", "buildXY", "y", "number", y
    return unless x?
    @build toBuild
    @intent = "build"
    @setTargetPos new Vector(x, y,), 'buildXY'
    if @actions.move and @distance(@targetPos, true) > @buildRange
      @setAction 'move'
    else
      @setAction 'build'
    return @block?() unless @commander?

  summon: (toBuild) ->
    #console.log @world.age, @id, "has gold", @gold, "with inventory gold", @world.getSystem("Inventory").goldForTeam(@team), "trying to summon", toBuild, "which is", @buildables[toBuild].goldCost, "and was trying to build", @toSummon
    @aiSystem ?= @world.getSystem "AI"
    angle = @world.rand.randf() * 2 * Math.PI
    placementAttempts = 8
    while placementAttempts--
      targetPos = new Vector @pos.x + 3 * Math.cos(angle), @pos.y + 3 * Math.sin(angle)
      break if @aiSystem.isPathClear @pos, targetPos, @, true
      angle += Math.PI / 4
    result = @buildXY toBuild, targetPos.x, targetPos.y
    @toSummon = @toBuild if toBuild in (@commandableTypes ? [])
    if @targetPos
      @targetPos.z += @pos.z - @depth / 2 if @pos.z > @depth / 2
    result

  costOf: (toBuild) ->
    if typeof toBuild is 'undefined'
      throw new ArgumentError "Check the cost of what?.", "costOf", "toBuild", "object", toBuild
    unless toBuild in @unitNames
      throw new ArgumentError "You need a string to check the cost of; one of [\"#{@buildTypes.join('\", \"')}\"]", "costOf", "toBuild", "object", toBuild
    @buildables[toBuild].goldCost or 0
    
  repair: (target) ->
    console.log 'todo: implement Builds repair, or make a new Component'

  update: ->
    return unless @intent is 'build' and @toBuild
    return if @toBuild.goldCost and @inventorySystem.goldForTeam(@team) < @toBuild.goldCost
    if @action is 'build' and @act()
      @performBuild()
    else
      if @action is 'move' and @distance(@targetPos, true) <= @buildRange
        @setAction 'build'
    
  performBuild: (poolName=undefined, spriteName=undefined, components=undefined) ->
    unless spriteName and components
      if @toBuild.thangTemplate and toBuildThang = @world.getThangByID @toBuild.thangTemplate
        spriteName = toBuildThang.spriteName
        components = _.cloneDeep toBuildThang.components
      else if toBuildThangType = @toBuild.thangType
        spriteName = _.find(@world.thangTypes, original: toBuildThangType)?.name
        components = _.cloneDeep @componentsForThangType toBuildThangType
    unless spriteName and components
      console.log @id, 'Builds problem: couldn\'t find thang to build for thangTemplate', @toBuild.thangTemplate, 'or thangType', @toBuild.thangType
      return
    @inventorySystem.subtractGoldForTeam @team, @toBuild.goldCost
    nextID = @toBuild.ids?.shift()
    thang = @spawn spriteName, components, nextID, poolName
    buildPos = @targetPos or @pos
    if @targetPos or @toBuild.offset
      if @toBuild.offset
        buildPos = Vector.add buildPos, @toBuild.offset, true
      else
        buildPos = buildPos.copy()
        buildPos.z = thang.pos.z
      thang.pos = buildPos
      if thang.move
        thang.hasMoved = true
      else
        thang.addTrackedProperties ['pos', 'Vector']
        thang.keepTrackedProperty 'pos'
    thang.setExists true
    thang.buildIndex = @built.length
    thang.builtBy = @
    thang.commander = @ if @toSummon is @toBuild
    thang.addCurrentEvent? 'built'
    @built.push thang
    @keepTrackedProperty 'built'
    thang.addTrackedProperties ['buildIndex', 'number']
    thang.keepTrackedProperty 'buildIndex'
    @brake?()
    @announceAction? "build \"#{@toBuild.type}\""
    #@setAction 'idle'  # Let's try keeping it on build to see if we can't do better animations for fast builds.
    @toBuild = null
    @toSummon = null
    @targetPos = null
    @justBuilt = thang if @plan
    @actionActivating = true
    @unblock?()
    @intent = undefined
    thang
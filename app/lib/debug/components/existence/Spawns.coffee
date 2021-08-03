Component = require 'lib/world/component'

Thang = require 'lib/world/thang'

module.exports = class Spawns extends Component
  @className: "Spawns"
  attach: (thang) ->
    @requiredThangTypes = (thang.requiredThangTypes ? []).concat _.filter(@requiredThangTypes)
    super thang
    thang.spawnPools = {}

  spawn: (thangTypeName, components, id=null, poolName=null) ->
    # Spawn a new Thang with the given properties and components. thangTypeName is the new spriteName.
    spawned = new Thang @world, thangTypeName, id
    # TODO: test this, adding fallbacks if needed for old levels with Thangs that spawn on other teams which have team neutrals
    if @team and @team isnt 'neutral'
      for component in components
        component[1].team = @team if component[1]?.team  # Make sure our spawnees are on our team.
    for component in components
      component[1].stateless = false if component[1]?.stateless  # stateless Thangs would never show up
    spawned.addComponents components...
    spawned.keepTrackedProperty 'exists'  # So that we don't pretend it always existed
    spawned.updateRegistration()
    if @hasEffects and spawned.hasEffects and @effects.length
      effects = _.cloneDeep @effects
      # TODO: Remove 'control' when the actual 'control' effect/spell is implemented.
      spawned.addEffect effect for effect in effects when effect.name not in ['sacrifice', 'soul-link', 'control', 'stick', 'phase-shift', "hide"]

    # Replace any old, non-existent spawn from the proper spawn pool
    poolName ?= spawned.spriteName
    pool = @spawnPools[poolName] ?= []
    for pooledSpawn, i in pool
      unless pooledSpawn.exists or pooledSpawn.isCollectable  # We should be able to re-use collectables, but it's not working...
        spawned.id = pooledSpawn.id
        pool[i] = spawned
        spawned.trackedPropertiesUsed = pooledSpawn.trackedPropertiesUsed  # So we don't pretend we never changed some of these
        @world.setThang spawned
        spawned.initialize?()
        return spawned

    # Or: no dead pool spawn available; add the new one
    pool.push spawned
    @world.thangs.unshift spawned
    @world.setThang spawned
    spawned.initialize?()
    spawned

  componentsForThangType: (original) ->
    unless @world.levelComponents and @world.thangTypes
      #console.error "Oops, #{@id} trying to load ThangTypes from level, but there is no level?"  # I guess it's okay if it's not in a worker.
      return 
    unless thangTypeModel = _.find(@world.thangTypes, original: original)
      console.error @id, 'could not find ThangType for', original, 'when trying to get ready to spawn one, of', @world.thangTypes
      return []
    components = []
    for component in thangTypeModel.components
      componentModel = _.find @world.levelComponents, (c) -> c.original is component.original and c.version.major is (component.majorVersion ? 0)
      componentClass = @world.loadClassFromCode componentModel.js, componentModel.name, 'component'
      @world.classMap[componentClass.className] ?= componentClass
      components.push [componentClass, component.config]
    components
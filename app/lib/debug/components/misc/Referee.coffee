Component = require 'lib/world/component'

Rectangle = require 'lib/world/rectangle'
Ellipse = require 'lib/world/ellipse'
Vector = require 'lib/world/vector'

module.exports = class Referee extends Component
  @className: 'Referee'
  isReferee: true
  # Things to make easier:
  # Position-based spawn triggers?
  # Ending world when enemies are blocked?
  # Checking gold collection status?
  # Generating doodads?

  # --- Setup ---
    
  constructor: (config) ->
    super config
    @rectangles ?= {}
    @ellipses ?= {}
    @points ?= {}
    @warnedBuildTypeTypos = {}
    @timeouts = {}
    
  attach: (thang) ->
    if @extraCode
      try
        js = CoffeeScript.compile @extraCode, bare: true
        try
          extraProperties = eval js
        catch e
          console.log "Referee #{thang.id} couldn't eval\n#{js}\nbecause", e
      catch e
        console.log "Referee #{thang.id} couldn't compile\n#{@extraCode}\nbecause", e
      delete @extraCode
    super thang
    if extraProperties?
      for key, value of extraProperties
        oldValue = thang[key]
        if typeof oldValue is 'function'
          thang.appendMethod key, value
        else
          thang[key] = value

  initialize: ->
    regionsToInitialize = []
    for name, rect of @rectangles ? {} when not rect.containsPoint
      regionsToInitialize.push name: name, rect: rect, shape: 'rectangle', klass: Rectangle, container: @rectangles
    for name, rect of @ellipses ? {} when not rect.containsPoint
      regionsToInitialize.push name: name, rect: rect, shape: 'ellipse', klass: Ellipse, container: @ellipses
    for region in regionsToInitialize
      rect = region.rect
      if rect.width
        region.container[region.name] = new region.klass rect.x, rect.y, rect.width, rect.height
      else
        midX = (rect[0].x + rect[1].x) / 2
        midY = (rect[0].y + rect[1].y) / 2
        width = Math.abs rect[1].x - rect[0].x
        height = Math.abs rect[1].y - rect[0].y
        region.container[region.name] = new region.klass midX, midY, width, height
    for name, point of @points ? {} when not point.isVector
      @points[name] = new Vector point.x, point.y
    @icontext = {}
    for name, text of @context ? {} when name
      
      @icontext[name] = @translate(name)
    @setUpLevel()
    

  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    @hero2 = @world.getThangByID 'Hero Placeholder 1'  # Only in multiplayer levels
    @setUpCoins() if @coinSpawn
    @setUpWaves() if @waves
    
  onFirstFrame: ->
    @onFirstFrameRan = true
    
  setUpCoins: ->
    @averageCoinValue = 0
    totalChance = 0
    for coin in @coinSpawn.spawnChances
      value = {'bronze-coin': 1, 'silver-coin': 2, 'gold-coin': 3, 'gem': 5}[coin.buildType] ? 1
      @averageCoinValue += coin.spawnChance * value
      totalChance += coin.spawnChance
    @averageCoinValue /= totalChance
    @totalCoinValue = 0

  setUpWaves: ->
    # Cut out any waves that only belong to particular seed buckets other than the one our random seed puts us into.
    # Sets up scaledPower for waves based on what difficulty level we're at, if applicable.
    @waves = _.filter @waves
    maxSeedBucket = 0
    for wave in @waves when wave.seedBuckets
      maxSeedBucket = Math.max maxSeedBucket, seedBucket for seedBucket in wave.seedBuckets
    if maxSeedBucket
      seedBucket = @world.rand.randf() % (maxSeedBucket + 1)
    @waves = (wave for wave in @waves when not wave.seedBuckets or (seedBucket in wave.seedBuckets))
    for wave in @waves
      wave.scaledPower = if wave.scalesWithDifficulty then wave.power * Math.pow(2, @world.difficulty ? 0) else wave.power
      for spawnChance in wave.spawnChances ? []
        unless spawnChance
          console.warn "Missing spawnChance in wave", wave.name ? wave
          continue
        spawnChance.power = @getBuildTypePower spawnChance.buildType, wave
      console.log "Assigned power #{wave.scaledPower} to wave #{wave.name} with difficulty #{@world.difficulty}" if @world.difficulty?
    
  # --- Runtime ---
  
  chooseAction: ->
    @onFirstFrame() unless @onFirstFrameRan
    @spawnCoins()
    @spawnWaves()
    @processTimeouts()
    
    teams = ['humans', 'ogres', 'neutral']
    @surviving = {}
    for team in teams
      @surviving[team] = (t for t in @world.thangs when t.team is team and t.health > 0)
      @controlMinionWaypoints t for t in @surviving[team]
    for team, thangs of @surviving
      # like @controlHumans thangs, if defined
      @['control' + _.string.capitalize team]? thangs
    @fixUpDynamicKillGoals()
    @checkVictory?() unless @victory? or @world.age is 0

  spawnCoins: ->
    return unless @coinSpawn
    if @coinSpawn.startingGold and @totalCoinValue < @coinSpawn.startingGold
      coinSpawnChance = @coinSpawn.startingGold
    else
      return if @coinSpawn.startTime and @world.age < @coinSpawn.startTime
      return if @coinSpawn.endTime and @world.age > @coinSpawn.endTime
      coinSpawnChance = @coinSpawn.goldPerSecond / @averageCoinValue * @world.dt
    while coinSpawnChance > 0  # If we need to build more than one coin per frame, we'll do it.
      if @world.rand.randf() < coinSpawnChance
        buildType = @pickBuildType @coinSpawn.spawnChances
        targetPos = @pickPointFromRegions (@rectangles[name] or @ellipses[name] for name in @coinSpawn.regions)
        coin = @instabuild buildType, targetPos.x, targetPos.y
        @totalCoinValue += coin.bountyGold
      --coinSpawnChance
      
  spawnWaves: ->
    return unless @waves
    @spawnsWaiting ?= []
    t = @world.age
    for wave in @waves ? []
      continue unless wave.startTime?
      continue if wave.ended
      continue if wave.startTime and t < wave.startTime
      continue if wave.endTime and t > wave.endTime
      wave.ended = true
      powerUsed = 0
      while true
        spawnChances = (sc for sc in wave.spawnChances when powerUsed + sc.power <= wave.scaledPower)
        break unless spawnChances.length
        buildType = @pickBuildType spawnChances
        powerUsed += @getBuildTypePower buildType, wave
        spawnTime = @world.rand.randf2 wave.startTime ? 0, wave.endTime ? wave.startTime ? 0
        #console.log wave.name, 'used power', powerUsed, 'of', wave.scaledPower, 'spawning', buildType, 'at', spawnTime
        @spawnsWaiting.push buildType: buildType, spawnTime: spawnTime, wave: wave
      @spawnsWaiting.sort (a, b) -> a.spawnTime - b.spawnTime
    while @spawnsWaiting[0]?.spawnTime <= @world.age
      spawn = @spawnsWaiting.shift()
      wave = spawn.wave
      if spawnPoint = wave.sharedSpawnPoint
        # Already decided for this wave, so don't recalculate.
        waypoints = wave.sharedWaypoints
      else
        # Calculate the spawn point and waypoints.
        nPointChoices = wave.points?.length ? 0
        nRegionChoices = wave.regions?.length ? 0
        if @world.rand.rand(nPointChoices + nRegionChoices) < nPointChoices
          path = (@points[name] for name in wave.points[@world.rand.rand wave.points.length])
          unless _.every path
            console.log "Error: missing at least one configured waypoint for wave", wave.name
          spawnPoint = path[0]
          waypoints = path.slice(1)
        else
          spawnPoint = @pickPointFromRegions (@rectangles[name] or @ellipses[name] for name in wave.regions)
          waypoints = null
        if wave.sharesSpawnPoint
          wave.sharedSpawnPoint = spawnPoint
          wave.sharedWaypoints = waypoints
      thang = @instabuild spawn.buildType, spawnPoint.x, spawnPoint.y
      if thang
        thang.waypoints = waypoints.slice() if waypoints
    
      # TODO: omit spawnTime for no auto-spawn.
      # TODO: implement the triggerLocations thing (name, type, triggerDistance)
      
  spawnWaveNamed: (name) ->
    wave = _.find @waves, name: name
    return console.log "Couldn't find wave named #{name}." unless wave
    wave.ended = false
    wave.startTime = @world.age
    delete wave.endTime if wave.endTime < @world.age
    @spawnWaves()
    
  pickBuildType: (spawns) ->
    totalChance = 0
    totalChance += spawn.spawnChance ? 1 for spawn in spawns
    n = @world.rand.randf() * totalChance
    for spawn in spawns
      if n <= (spawn.spawnChance ? 1)
        return spawn.buildType
      n -= spawn.spawnChance
    console.error "Programming mistake finding a build type!", n, totalChance, spawns
    spawn.buildType

  pickPointFromRegions: (regions) ->
    # Does not handle rotated regions, since the chooser doesn't let you do those anyway. Wouldn't be too hard to add.
    [minX, minY, maxX, maxY] = [Infinity, Infinity, -Infinity, -Infinity]
    for region in regions
      minX = Math.min minX, region.x - region.width
      minY = Math.min minY, region.y - region.height
      maxX = Math.max maxX, region.x + region.width
      maxY = Math.max maxY, region.y + region.height
    attempts = 0  # Protect against infinite loop with some weird region misconfiguration or very, very tiny disjoint regions
    while attempts < 1000
      p = new Vector @world.rand.randf2(minX, maxX), @world.rand.randf2(minY, maxY)
      for region in regions
        console.log 'region is not a rectangle/ellipse', region, 'with cp', region.containsPoint, 'and all keys', _.keys(region) unless region?.containsPoint
        return p if region.containsPoint p
      ++attempts
    console.error "Couldn't find a random point within given regions in #{attempts} tries."
    new Vector regions[0].x, regions[0].y
    
  instabuild: (buildType, x, y, poolName=undefined) ->
    unless @buildXY
      console.error @id, "didn't have buildXY method for use in Referee's instabuild at time", @world.age, "for", buildType, "at", x, y, "with buildTypes", @buildTypes
      return null
    @buildXY buildType, x, y
    thang = @performBuild poolName
    thang
    
  controlMinionWaypoints: (thang) ->
    return false if thang.dead
    return false unless thang.waypoints?.length
    waypoint = thang.waypoints[0]
    thang.move waypoint
    if thang.distance(waypoint) < 4
      thang.waypoints.shift()
      thang.setAction 'idle'
      thang.setTargetPos null
    true
    
  fixUpDynamicKillGoals: ->
    return unless @world.goalManager.goalStates['ogres-die']?
    return unless _.every @waves, 'ended'
    return if @spawnsWaiting?.length
    return if @surviving.ogres?.length
    @world.setGoalState 'ogres-die', 'success'
    
  getBuildTypePower: (buildType, wave) ->
    buildTypePower = @world.getSystem('Existence').buildTypePower
    unless buildTypePower[buildType] or @warnedBuildTypeTypos[buildType]
      console.log "Warning: no power estimate for unknown buildType #{buildType}. Check bottom of Existence System code for known buildType strings."
      @warnedBuildTypeTypos[buildType] = true
    buildTypePower[buildType] or wave.power / 15
  
  setTimeout: (callback, delay) ->
    key = _.uniqueId()
    @timeouts[key] = {time: @world.age + delay, callback: callback}
    return key

  setInterval: (callback, interval) ->
    key = _.uniqueId()
    @timeouts[key] = {time: @world.age + interval, callback: callback, repeat: interval}
    return key

  processTimeouts: () ->
    for key, obj of @timeouts
      if @world.age >= obj.time
        obj.callback() unless obj.forDelete
        if obj.repeat?
          @timeouts[key] = {time: obj.time + obj.repeat, callback: obj.callback, repeat: obj.repeat}
        else
          delete(@timeouts[key])

  clearTimeout: (key) ->
    if @timeouts[key]
      @timeouts[key].forDelete = true
      @timeouts[key].repeat = undefined

  translate: (target) ->
    # TODO: some of this logic is copied from app/core/utils.coffee, which we can't access here; DRY somehow?
    unless english = @context[target]
      console.error "Couldn't find Referee context string for key", target
      return target
      
    language = @world.language or 'en-US'
    generalResult = null
    fallBackResult = null
    fallForwardResult = null  # If a general language isn't available, the first specific one will do.
    fallSidewaysResult = null  # If a specific language isn't available, its sibling specific language will do.
    matches = (/\w+/gi).exec(language)
    generalName = matches[0] if matches
  
    for localeName, locale of @i18n ? {}
      continue if localeName is '-'
      if target of locale.context
        result = locale.context?[target]
      else continue
      return result if localeName is language
      generalResult = result if localeName is generalName
      fallBackResult = result if localeName is 'en'
      fallForwardResult = result if localeName.indexOf(language) is 0 and not fallForwardResult?
      fallSidewaysResult = result if localeName.indexOf(generalName) is 0 and not fallSidewaysResult?
  
    return generalResult if generalResult?
    return fallForwardResult if fallForwardResult?
    return fallSidewaysResult if fallSidewaysResult?
    return fallBackResult if fallBackResult?
    return @context[target] if target of @context
    null
    
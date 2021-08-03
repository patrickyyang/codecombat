Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class StrandedInTheDunesReferee extends Component
  @className: 'StrandedInTheDunesReferee'
  chooseAction: ->
    @configure()
    @checkActorEvents()
    @decrementTimers()
    @jibberJabber()
    @resetGravity()
    @cleanUpYaks()
    @fixUnitAggro()
    @handleLevelWrap()
    @checkRaven()
    @checkPotions()
    @sectorPulse()
    @bossEncounter()
  
  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    
    @disableEnemies = false
    
    @actors =
      "elder": @world.getThangByID 'Village Elder'
      "son": @world.getThangByID 'Elder\'s Son'
      "yakky": @world.getThangByID 'Yakky'
      "hector": @world.getThangByID 'Hector'
      "durfkor": @world.getThangByID 'Durfkor'
      "katelyn": @world.getThangByID 'Katelyn'
      "mary": @world.getThangByID 'Mary'
      "raven": @world.getThangByID 'Raven'
    
    @actorEvents =
      "elder-intro-move": false
      "raven-spawned": false
      "raven-start-positioning": false
      "raven-positioning": false
      "raven-positioned": false
      "raven-swoop-start": false
      "raven-swoop-progress": false
      "raven-swoop-return": false
    
    for name, actor of @actors
      actor.isAttackable = false
    
    @potionRegistry = []
    
    @terrainObjects = [
      "desert-wall-1"
      "desert-wall-2"
      "desert-wall-3"
      "desert-wall-4"
      "desert-wall-5"
      "desert-wall-6"
      "desert-wall-7"
      "desert-wall-8"
      "desert-rubble-1"
      "desert-rubble-2"
      "desert-bones-1"
      "desert-bones-2"
      "desert-bones-3"
      "scorpion"
      "snake"
    ]
    
    @terrainCleanupObjects = [
      "desert-wall-1"
      "desert-wall-2"
      "desert-wall-3"
      "desert-wall-4"
      "desert-wall-5"
      "desert-wall-6"
      "desert-wall-7"
      "desert-wall-8"
      "desert-house-1"
      "desert-house-2"
      "desert-house-3"
      "desert-house-4"
      "desert-well"
      "desert-rubble-1"
      "desert-rubble-2"
      "desert-rubble-3"
      "desert-palm-1"
      "desert-palm-2"
      "desert-green-1"
      "desert-green-2"
      "desert-pillar"
      "desert-skullcave"
      "desert-pyramid"
      "desert-bones-1"
      "desert-bones-2"
      "desert-bones-3"
      "desert-shrub-big-1"
      "desert-shrub-big-2"
      "scorpion"
      "snake"
      "fire-trap"
    ]
    
    @events = [
      "melee-skeletons"
      "shaman-skeletons"
      "archer-skeletons"
    ]
    
    @eventOdds =
      "sand-yaks": 60
      "melee-skeletons": 90
      "shaman-skeletons": 95
      "archer-skeletons": 95
    
    @timers =
      "wrapTimer": 0
      "eventTimer": 0
      "sandYakTimer": 0
      "bossDelay": 0
      "bossfall": 0
      "swoopDelay" : 0
    
    @bossEvents =
      "started": false
      "spawned": false
      "fallen": false
      "dialog1": false
      "dialog2": false
      "moving": false
      "positioned": false
      "wave1": false
      "taunt1": false
      "wave2": false
      "wave2_2" : false
      "wave2_3": false
      "taunt2": false
    
    @leftWrapPending = false
    @rightWrapPending = false
    @numberOfEvents = 3
    @totalStacksBeforeBoss = 3
    @maxNumTerrainObjects = 24
    @maxNumFireTraps = 12
    @bossStackGenerated = false
    @currentNumPotions = 0
  
  configure: ->
    return unless not @configured
    @currentStack = 0
    #
    # configure stack 0
    #   | This is setting up the landscape for the village
    #
    @terrainStack = [[
      {obj: "desert-wall-1", x: 41.59, y: 54.800000000000004}
      {obj: "desert-wall-1", x: 31.45, y: 47.76}
      {obj: "desert-wall-1", x: 12.05, y: 49.63}
      {obj: "desert-wall-2", x: 32.09, y: 67.88}
      {obj: "desert-wall-2", x: 21.8, y: 56.32}
      {obj: "desert-wall-2", x: 30.59, y: 3.53}
      {obj: "desert-wall-2", x: -4.540000000000001, y: 46.17, r: 3.141592653589793}
      {obj: "desert-wall-2", x: -1.7200000000000006, y: 37.2, r: 3.141592653589793}
      {obj: "desert-wall-2", x: -5.52, y: 29.98, r: 3.141592653589793}
      {obj: "desert-wall-2", x: -2.5600000000000005, y: 22.87, r: 3.141592653589793}
      {obj: "desert-wall-3", x: 58.92, y: 16.67}
      {obj: "desert-wall-4", x: 10.41, y: 66}
      {obj: "desert-wall-4", x: 10.53, y: 3.82}
      {obj: "desert-wall-4", x: 49.88, y: -0.3700000000000001}
      {obj: "desert-wall-5", x: 55.67, y: 58.15}
      {obj: "desert-wall-6", x: 5.11, y: 57.58, r: 0.52}
      {obj: "desert-wall-7", x: 49.02, y: 45.59}
      {obj: "desert-wall-7", x: 9.16, y: 42.4}
      {obj: "desert-wall-7", x: 56.21, y: 7.140000000000001}
      {obj: "desert-wall-8", x: 51.29, y: 65.45}
      {obj: "desert-wall-8", x: -3.030000000000001, y: 11.77, r: 3.141592653589793}
      {obj: "desert-wall-8", x: 68.46000000000001, y: 67.69, r: 3.141592653589793}
      {obj: "desert-house-1", x: 40.39, y: 41.47, r: 3.141592653589793}
      {obj: "desert-house-2", x: 12.13, y: 35.38, r: 0.78}
      {obj: "desert-house-2", x: 48.56, y: 40, r: 3.141592653589793}
      {obj: "desert-house-2", x: 14.97, y: 13.03, r: -1.5707963267948966}
      {obj: "desert-house-3", x: 21.35, y: 41.74, r: 0.78}
      {obj: "desert-house-3", x: 43.36, y: 7.2, r: 3.141592653589793}
      {obj: "desert-house-4", x: 7.71, y: 28.78, r: 0.78}
      {obj: "desert-house-4", x: 23.97, y: 10.28, r: 0.78}
      {obj: "desert-well", x: 8.07, y: 17.3}
      {obj: "desert-rubble-3", x: 59.36, y: 44.47}
      {obj: "desert-palm-1", x: 58.050000000000004, y: 23.37}
      {obj: "desert-palm-2", x: 27.810000000000002, y: 41.43}
      {obj: "desert-green-1", x: 58.81, y: 40.71}
      {obj: "desert-green-1", x: 7.97, y: 13.97}
      {obj: "desert-green-2", x: 36.7, y: 41.15}
      {obj: "desert-green-2", x: 19.46, y: 14.41}
      {obj: "desert-green-2", x: 11.44, y: 31.17}
      {obj: "desert-pillar", x: 66.62, y: 21.63}
      {obj: "desert-pillar", x: 60.77, y: 41.72}
      {obj: "desert-pillar", x: 67.7, y: 18.31}
      {obj: "desert-pillar", x: 74.68, y: 25.29}
      {obj: "desert-pillar", x: 86.89, y: 26.990000000000002}
      {obj: "desert-pillar", x: 98.59, y: 26.990000000000002}
      {obj: "desert-pillar", x: 111.24000000000001, y: 27.560000000000002}
      {obj: "desert-pillar", x: 71.7, y: 46.49}
      {obj: "desert-pillar", x: 85.12, y: 48.28}
      {obj: "desert-pillar", x: 98.44, y: 47.92}
      {obj: "desert-pillar", x: 111.24000000000001, y: 46.64}
    ]]
    
    #
    # configure boss stack
    #   | This is setting up the landscape for the boss stack
    #
    @bossStack = [
      {obj: "desert-wall-1", x: 30.34, y: 15.39}
      {obj: "desert-wall-1", x: 90.26, y: 14.84, r: 3.141592653589793}
      {obj: "desert-wall-2", x: 31.89, y: 43.2}
      {obj: "desert-wall-2", x: 88.72, y: 43.010000000000005, r: 3.141592653589793}
      {obj: "desert-wall-3", x: 45.49, y: 13.46}
      {obj: "desert-wall-3", x: 73.94, y: 13.75, r: 3.141592653589793}
      {obj: "desert-wall-4", x: 23.380000000000003, y: 34.19}
      {obj: "desert-wall-4", x: 97.24, y: 34.25, r: 3.141592653589793}
      {obj: "desert-wall-6", x: 16.4, y: 43.42, r: 0.52}
      {obj: "desert-wall-6", x: 15.69, y: 61.75, r: 0.52}
      {obj: "desert-wall-6", x: 104.28, y: 61.71000000000001}
      {obj: "desert-wall-6", x: 104.4, y: 43.46, r: 3.141592653589793}
      {obj: "desert-wall-7", x: 28.07, y: 55.15}
      {obj: "desert-wall-7", x: 35.22, y: 48.08}
      {obj: "desert-wall-7", x: 26.86, y: 22.400000000000002}
      {obj: "desert-wall-7", x: 92.74, y: 55.36, r: 3.141592653589793}
      {obj: "desert-wall-7", x: 85.58, y: 48.07, r: 3.141592653589793}
      {obj: "desert-wall-7", x: 93.68, y: 22.11, r: 3.141592653589793}
      {obj: "desert-wall-7", x: 19.62, y: 51.4}
      {obj: "desert-wall-7", x: 101.06, y: 51.43, r: 3.141592653589793}
      {obj: "desert-skullcave", x: 55.89, y: 51.99, r: 0.78, c: true}
      {obj: "desert-pyramid", x: 60.38, y: 56.88, r: 0.78}
      {obj: "desert-pillar", x: 51, y: 54.95, c: true}
      {obj: "desert-pillar", x: 65.35, y: 49.18, c: true}
      {obj: "desert-rubble-1", x: 70.26, y: 54.230000000000004, r: 0.78}
      {obj: "desert-rubble-2", x: 70.06, y: 61.97}
      {obj: "desert-bones-1", x: 114.93, y: 8.32}
      {obj: "desert-bones-2", x: 102.74000000000001, y: 29.12}
      {obj: "desert-bones-2", x: 9.120000000000001, y: 45.69}
      {obj: "desert-bones-3", x: 113.33, y: 56.72}
      {obj: "desert-bones-3", x: 40.980000000000004, y: 19.86}
      {obj: "desert-bones-3", x: 42.550000000000004, y: 65.87}
      {obj: "desert-shrub-big-1", x: 13.84, y: 28.11}
      {obj: "desert-shrub-big-1", x: 74.81, y: 44.89}
      {obj: "desert-shrub-big-2", x: 112.67, y: 41.35}
      {obj: "desert-shrub-big-2", x: 26.330000000000002, y: 9.5}
    ]
    
    @stackSpawns = [0]
    @configureThangTemplates()
    @populateTerrain()
    @configured = true
  
  configureThangTemplates: ->
    #
    # configureThangTemplates
    #   | sets build power for custom thang templates so they spawn correctly
    #
    btp = @world.getSystem('Existence').buildTypePower
    btp['brittle-skeleton'] = 75.00
    btp['brittle-skeleton-shaman'] = 95.00
    btp['brittle-skeleton-archer'] = 95.00
  
  configureStack: ->
    #
    # configureStack
    #   | configures a stack called anytime you wrap to a new or previous stack
    #
    @cleanUpCorpses()
    
    if @terrainStack.length - 1 is @totalStacksBeforeBoss and not @bossStackGenerated
      @bossStackGenerated = true
      @populateTerrain(true)
      @spawnBossGuards()
    else
      @populateTerrain()
    
    if @currentStack is 0
      # bring back npcs
      for name, actor of @actors
        actor.setExists(true)
    else
      # hide npcs
      for name, actor of @actors
        actor.setExists(false)
    
    @world.getSystem("AI").onObstaclesChanged()
  
  configureYak: (yak) ->
    yak.maxSpeed = 20
    yak.currentSpeedRatio = 1
    yak.addTrackedProperties ['maxSpeed', 'number']
    yak.keepTrackedProperty 'maxSpeed'
    yak.addTrackedProperties ['currentSpeedRatio', 'number']
    yak.keepTrackedProperty 'currentSpeedRatio'
  
  resetGravity: ->
    return unless (not @bossEvents.spawned or @timers.bossfall > 0 or @skeletonKing.pos.z <= 0)
    for potion in @potionRegistry
      if potion.exists and potion.pos.z > 0
        return
    @world.gravity = 9.81
  
  decrementTimers: ->
    for name, timer of @timers
      @timers[name] -= @world.dt
  
  checkActorEvents: ->
    #
    # checkActorEvents
    #   | any events related to actors
    #
    if @world.age >= 0 and not @actorEvents['elder-intro-move']
      @actors.elder.move({x: 30, y: 29});
      @actorEvents['elder-intro-move'] = true
  
  jibberJabber: ->
    #
    # jibberJabber
    #   | simply facilitates timed npc chatter
    #
    now = Math.round(@world.age)
    emotes = [
      {time: 0, actor: @actors.elder, message: "Please help me hero!"}
      {time: 4, actor: @actors.yakky, message: "Moo?"}
      {time: 6, actor: @actors.yakky, message: "Meow?"}
      {time: 8, actor: @actors.yakky, message: "Ribbit?"}
    ]
    
    for emote in emotes
      if now is emote.time
        emote.actor.say? emote.message
  
  checkRaven: ->
    #
    # checkRaven
    #   | show raven to give you guidance when needed
    #
    if @currentStack > 0 and not @bossStackGenerated
      #
      # area cleared
      #   | if not in town and all enemies are cleared, direct the player to continue forwards
      #
      if @stackSpawns[@currentStack] is 0 and not @actorEvents["raven-spawned"] and @enemiesCleared()
        @actorEvents["raven-spawned"] = true
        @actors.raven.pos.x = @hero.pos.x + 5
        @actors.raven.pos.y = @hero.pos.y + 5
        @actors.raven.setExists(true)
        @actors.raven.say? "Continue forward to find more skeletons!"
      else if @stackSpawns[@currentStack] is 0 and @actorEvents["raven-spawned"]
        @actors.raven.move(Vector.subtract(@actors.raven.pos, @hero.pos).normalize().multiply(7).add(@hero.pos))
    else if @currentStack is @terrainStack.length - 1 and @bossStackGenerated
      #
      # boss encounter
      #   | if in the boss stack direct the player to investigate the ruins
      #
      if not @actorEvents["raven-spawned"]
        @actorEvents["raven-spawned"] = true
        @actors.raven.pos.x = @hero.pos.x + 5
        @actors.raven.pos.y = @hero.pos.y + 5
        @actors.raven.setExists(true)
        @actors.raven.say? "You are getting close now, investigate those ruins!"
      else if @actorEvents["raven-spawned"] and not @actorEvents["raven-start-positioning"]
        @actors.raven.move(Vector.subtract(@actors.raven.pos, @hero.pos).normalize().multiply(7).add(@hero.pos))
  
  ravenPerch: ->
    #
    # ravenPerch
    #   | use this after you move the raven to a pillar and you want him to sit still
    #
    @actors.raven.pos.z = 12
    @actors.raven.rotation = 90
    @actors.raven.velocity.multiply 0
    @actors.raven.setAction null
    @actors.raven.setTarget null
    
  ravenMovement: ->
    #
    # ravenMovement
    #   | handles the ravens movement during the boss encounter
    #
    if @actorEvents["raven-start-positioning"] and not @actorEvents["raven-positioned"]
      if not @actorEvents["raven-positioning"]
        if @actors.raven.pos.x isnt 69 and @actors.raven.pos.y isnt 33
          @actors.raven.moveXY 69, 33
        else 
          @actorEvents["raven-positioning"] = true
          @actors.raven.moveXY 51, 54
      else if @actorEvents["raven-positioning"]
        if @actors.raven.pos.x is 51 and @actors.raven.pos.y is 54 and not @actorEvents["raven-positioned"]
          @actorEvents["raven-positioned"] = true
          @ravenPerch()
    else if @actorEvents["raven-swoop-start"] and not @actorEvents["raven-swoop-return"] and not @actorEvents["raven-return-village"]
      if not @actorEvents["raven-swoop-progress"] 
        if @actors.raven.pos.x isnt @ravenDropPos.x and @actors.raven.pos.y isnt @ravenDropPos.y
          @actors.raven.moveXY @ravenDropPos.x, @ravenDropPos.y
        else 
          @world.gravity = 269.81
          p = @instabuild("health-potion", @ravenDropPos.x, @ravenDropPos.y)
          p.pos.z = 9
          @potionRegistry.push p
          @currentNumPotions++
          @actorEvents["raven-swoop-progress"] = true
          @actors.raven.moveXY 51, 54
      else if @actorEvents["raven-swoop-progress"]
        if @actors.raven.pos.x is 51 and @actors.raven.pos.y is 54 and not @actorEvents["raven-swoop-return"]
          @actorEvents["raven-swoop-return"] = true
          @ravenPerch()
    else if @actorEvents["raven-swoop-start"] and @actorEvents["raven-swoop-return"]
      @actorEvents["raven-swoop-start"] = false
      @actorEvents["raven-swoop-progress"] = false
      @actorEvents["raven-swoop-return"] = false
  
  checkPotions: ->
    potions = @findPotions()
    if potions.length < @currentNumPotions
      @hero.health += @hero.maxHealth / 2.5
      @currentNumPotions = potions.length
    
  findPotions: ->
    potions = _.filter @potionRegistry, exists: true
    potions
  
  sectorPulse: ->
    #
    # sectorPulse
    #   | This runs every frame and runs an event if it needs to occur
    #
    if not @disableEnemies and not @bossStackGenerated
      if @generateYakHerd()
        #
        # sand yak event
        #   | Independent event so they don't happen as often as skeleton events
        #   | Does not count against the event spawns count per stack
        #
        yaks = (t for t in @world.thangs when t.type is "sand-yak" and t isnt @actors.yakky and not t.dead)
        if yaks.length is 0
          # first herd, spawn with referee
          @assignWaveRegion("sand-yaks", "yak-herd", new Rectangle(117, 30, 25.0, 25.0, 0))
          @spawnWaveNamed "sand-yaks"
          yaks = (t for t in @world.thangs when t.isAttackable and t.type is "sand-yak" and t isnt @actors.yakky and t isnt @hero)
          for yak in yaks
            @configureYak yak
            yak.move({x: -14, y: 30})
        else
          # not the first herd, re-use old yaks
          @createRectangle("yak-herd", new Rectangle(117, 30, 25.0, 25.0, 0))
          for yak in yaks
            @configureYak yak
            spawnPoint = @pickPointFromRegions([@rectangles["yak-herd"]])
            yak.pos = spawnPoint
            yak.setExists(true)
            yak.move({x: -14, y: 30})
        
        @timers.sandYakTimer = 10
      
      event = @chooseEvent()
      if event
        rect = new Rectangle(@hero.pos.x, 30, 45.0, 20.0, 0)
        rect.x = Math.max 25, Math.min(90, rect.x)
        if event is "melee-skeletons"
          #
          # melee skeleton event
          #   | counts against the event spawns count per stack
          #
          @assignWaveRegion("melee-skeletons", "skeleton-attack", rect)
          @spawnWaveNamed "melee-skeletons"
          skeletons = (t for t in @world.thangs when t.isAttackable and t.type is "brittle-skeleton" and t.exists and t isnt @hero)
          for skeleton in skeletons
            skeleton.attack @hero
          @timers.eventTimer = 6
          @stackSpawns[@currentStack]--
        else if event is "shaman-skeleton"
          #
          # shaman skeleton event
          #   | spawns shaman skeletons counts against event spawns count per stack
          #
          @assignWaveRegion("shaman-skeletons", "skeleton-attack", rect)
          @spawnWaveNamed "shaman-skeletons"
          skeletons = (t for t in @world.thangs when t.isAttackable and t.type is "brittle-skeleton-shaman" and t.exists and t isnt @hero)
          for skeleton in skeletons
            skeleton.attack @hero
          @timers.eventTimer = 6
          @stackSpawns[@currentStack]--
        else if event is "archer-skeletons"
          #
          # archer skeleton event
          #   | spawns archer skeletons counts against event spawns count per stack
          #
          @assignWaveRegion("archer-skeletons", "skeleton-attack", rect)
          @spawnWaveNamed "archer-skeletons"
          skeletons = (t for t in @world.thangs when t.isAttackable and t.type is "brittle-skeleton-archer" and t.exists and t isnt @hero)
          for skeleton in skeletons
            skeleton.attack @hero
          @timers.eventTimer = 6
          @stackSpawns[@currentStack]--
  
  generateYakHerd: ->
    #
    # generateYakHerd
    #   | returns true if a yak herd should be generated
    #
    return false unless @timers.sandYakTimer <= 0 and @currentSector() is "sector1"
    r = Math.round(@world.rand.randf2(1, 100))
    return r >= @eventOdds["sand-yaks"]
  
  chooseEvent: ->
    #
    # chooseEvent
    #   | This chooses a random event and determines if the eventOdds say it should occur
    #
    return false unless @timers.eventTimer <= 0 and @stackSpawns[@currentStack] > 0 and @currentSector()
    r = Math.round(@world.rand.randf2(0, @events.length - 1))
    if (typeof @events[r] isnt "undefined")
      r2 = Math.round(@world.rand.randf2(1, 100))
      if r2 >= @eventOdds[@events[r]]
        return @events[r]
    false
  
  currentSector: ->
    #
    # currentSector
    #   | returns which sector the player is currently standing in
    #
    return sector for sector in ['sector1', 'sector2', 'sector3'] when @rectangles[sector].containsPoint @hero.pos
    false
  
  createRectangle: (name, rect) ->
    #
    # createRectangle
    #   | This creates a rectangle that can be used with spawn waves or triggers
    #
    @rectangles[name] = rect
  
  assignWaveRegion: (wave, region, rect) ->
    #
    # assignWaveRegion
    #   | creates a spawn rectangle and then assigns it to the specified wave
    #
    @createRectangle region, rect
    _.find(@waves, name: wave).regions = [region]
  
  fixUnitAggro: ->
    #
    # fixUnitAggro
    #   | Fix aggro on yaks who step on a fire trap and on skeletons who are going after a yak who no longer exists
    #
    skeletons = (t for t in @world.thangs when t.isAttackable and (t.type is "brittle-skeleton" or t.type is "brittle-skeleton-shaman") and t.exists and t isnt @hero)
    for skeleton in skeletons
      if skeleton.target
        if not skeleton.target.exists or skeleton.target.dead
          skeleton.setTarget(@hero)
    
    yaks = (t for t in @world.thangs when t.isAttackable and t.type is "sand-yak" and t isnt @actors.yakky and t.exists and t isnt @hero)
    for yak in yaks
      if yak.target
        if not yak.target.exists or yak.target.dead or yak.target.type is 'fire-trap'
          yak.setTarget(null)
          yak.lastAttacker = null
          yak.move({x: -14, y: 36})
      else if yak.targetPos?.x > 0
        yak.move({x: -14, y: 36})
  
  cleanUpYaks: (wipe) ->
    #
    # cleanUpYaks
    #   | hides the yak herd as soon as they cross the 6 x axis or if there are less than 5 left or it's a forceful wipe (level wrap)
    #
    if typeof wipe is "undefined"
      wipe = false
    
    yaks = (t for t in @world.thangs when t.isAttackable and t.type is "sand-yak" and t.exists and t isnt @hero)
    for yak in yaks
      if yaks.length <= 5 or yak.pos.x <= 6 or wipe
        yak.setExists(false)
  
  cleanUpCorpses: ->
    #
    # cleanUpCorpses
    #   | removes corpses TODO: store them so i can add them back if you return to a stack
    #
    corpses = @world.getSystem('Combat').corpses.slice()
    for corpse in corpses
      corpse.setExists(false)
  
  spawnBossGuards: ->
    #
    # spawnBossGuards
    #   | spawns the two guards at entrance to boss compound abd places event start marker and rectangle
    #
    @instabuild("brittle-skeleton", 55, 8)
    @instabuild("brittle-skeleton", 65, 8)
    @bossStartMarker = @instabuild("x-mark-red", 60, 15)
    @createRectangle("boss-event-start", new Rectangle(60, 15, 20.0, 10.0, 0))
    
  bossEncounter: ->
    #
    # bossEncounter
    #   | this method encompasses all of the logic surrounding the boss encounter
    #
    if @bossStackGenerated
      @ravenMovement()
      if @rectangles['boss-event-start'].containsPoint(@hero.pos) and not @bossEvents.started and @enemiesCleared()
        @bossEvents.started = true
        @actorEvents["raven-start-positioning"] = true
        @bossStartMarker.setExists false
        @bossEnv = @instabuild("env", 60, 35)
        @bossEnv.say? "*the ground begins to rumble*"
        @timers.bossDelay = 3
      else if @bossEvents.started and not @bossEvents.spawned and @timers.bossDelay <= 0
        @bossEvents.spawned = true
        @world.gravity = 269.81
        @skeletonKing = @instabuild("brittle-skeleton-king", 60, 35, 'Skeleton King')
        @skeletonKing.pos.z = 30
        @skeletonKing.isAttackable = false
        @timers.bossfall = 0.1
        @bossFallModifier = 0.25
      else if @bossEvents.spawned and @timers.bossfall <= 0 and @skeletonKing.pos.z > 0
        @timers.bossfall = 0.05
        newZ = @skeletonKing.pos.z - @bossFallModifier
        @skeletonKing.pos.z = if newZ < 0 then 0 else newZ
        @bossFallModifier = @bossFallModifier * 2
      else if @bossEvents.spawned and not @bossEvents.fallen and @skeletonKing.pos.z <= 0
        @bossEvents.fallen = true
        @world.gravity = 9.81
      else if @bossEvents.fallen and not @bossEvents.dialog1
        @bossEvents.dialog1 = true
        @timers.bossDelay = 5
        @skeletonKing.sayWithDuration? 5.0, "You have slain many of my minions and now must pay the price... in blood."
      else if @bossEvents.dialog1 and not @bossEvents.dialog2 and @timers.bossDelay <= 0
        @bossEvents.dialog2 = true
        @timers.bossDelay = 5
        @skeletonKing.sayWithDuration? 5.0, "You will not save Okar from his fate, but it will be amusing to watch you try!"
      else if @bossEvents.dialog2 and not @bossEvents.moving and @timers.bossDelay <= 0
        @bossEvents.moving = true
        @skeletonKing.move {x: 60, y: 49}
        @spawnAndAggroUnit "brittle-skeleton", 47, 31, @hero
        @spawnAndAggroUnit "brittle-skeleton", 52, 35, @hero
        @spawnAndAggroUnit "brittle-skeleton", 57, 39, @hero
        @spawnAndAggroUnit "brittle-skeleton", 62, 39, @hero
        @spawnAndAggroUnit "brittle-skeleton", 67, 35, @hero
        @spawnAndAggroUnit "brittle-skeleton", 72, 31, @hero
      else if @bossEvents.moving and not @bossEvents.positioned and Math.round(@skeletonKing.pos.x) is 60 and Math.round(@skeletonKing.pos.y) is 49
        @bossEvents.positioned = true
        @timers.bossDelay = 4
        @skeletonKing.rotation = 270
        @skeletonKing.setAction null
      else if @bossEvents.positioned and @timers.bossDelay <= 0 and not @bossEvents.wave1
        @bossEvents.wave1 = true
        @timers.bossDelay = 5
        @timers.swoopDelay = 7
        @skeletonKing.say? "Rise, my children, and protect me!"
        _.find(@waves, name: "archer-skeletons").scaledPower = 95.0
        @assignWaveRegion("archer-skeletons", "boss-top-left", new Rectangle(48, 51, 3.0, 3.0, 0))
        @spawnWaveNamed "archer-skeletons"
        _.find(@waves, name: "shaman-skeletons").scaledPower = 95.0
        @assignWaveRegion("shaman-skeletons", "boss-top-right", new Rectangle(70, 48, 3.0, 3.0, 0))
        @spawnWaveNamed "shaman-skeletons"
        skeletons = (t for t in @world.thangs when t.isAttackable and t.type in ["brittle-skeleton-archer", "brittle-skeleton-shaman"] and t.exists and t isnt @hero)
        for skeleton in skeletons
          skeleton.attack @hero
      else if @bossEvents.wave1 and @timers.swoopDelay <= 0 and not @actorEvents["raven-swoop-start"] and not @actorEvents["raven-return-village"]
        @actorEvents["raven-swoop-start"] = true
        @timers.swoopDelay = 17
        @createRectangle("raven-drop-zone", new Rectangle(60, 34, 12.0, 12.0, 0))
        @ravenDropPos = @pickPointFromRegions([@rectangles["raven-drop-zone"]])
        @actors.raven.sayWithDuration? 5.0, "Hero, here's a little something to help out!"
      else if @bossEvents.wave1 and not @bossEvents.taunt1 and @enemiesCleared()
        @bossEvents.taunt1 = true
        @skeletonKing.sayWithDuration? 5.0, "That was a nice warm-up. Let's see how you do with a real challenge."
        @timers.bossDelay = 8
      else if @bossEvents.taunt1 and not @bossEvents.wave2 and @timers.bossDelay <= 0
        @bossEvents.wave2 = true
        @timers.bossDelay = 3
        @spawnAndAggroUnit "brittle-skeleton", 47, 33, @hero
        @spawnAndAggroUnit "brittle-skeleton", 57, 25, @hero
        @spawnAndAggroUnit "brittle-skeleton", 62, 25, @hero
        @spawnAndAggroUnit "brittle-skeleton", 72, 33, @hero
      else if @bossEvents.wave2 and not @bossEvents.wave2_2 and @timers.bossDelay <= 0
        @bossEvents.wave2_2 = true
        @timers.bossDelay = 3
        @skeletonKing.say? "Rise, my children, and protect me!"
        _.find(@waves, name: "shaman-skeletons").scaledPower = 95.0
        @assignWaveRegion("shaman-skeletons", "boss-bottom-left", new Rectangle(41, 26, 3.0, 3.0, 0))
        @spawnWaveNamed "shaman-skeletons"
        _.find(@waves, name: "archer-skeletons").scaledPower = 95.0
        @assignWaveRegion("archer-skeletons", "boss-bottom-right", new Rectangle(79, 29, 3.0, 3.0, 0))
        @spawnWaveNamed "archer-skeletons"
      else if @bossEvents.wave2_2 and not @bossEvents.wave2_3 and @timers.bossDelay <= 0
        @bossEvents.wave2_3 = true
        @skeletonKing.say? "Rise, my children, and protect me!"
        _.find(@waves, name: "archer-skeletons").scaledPower = 95.0
        @assignWaveRegion("archer-skeletons", "boss-top-left", new Rectangle(48, 51, 3.0, 3.0, 0))
        @spawnWaveNamed "archer-skeletons"
        _.find(@waves, name: "shaman-skeletons").scaledPower = 95.0
        @assignWaveRegion("shaman-skeletons", "boss-top-right", new Rectangle(70, 48, 3.0, 3.0, 0))
        @spawnWaveNamed "shaman-skeletons"
      else if @bossEvents.wave2_3 and not @bossEvents.taunt2 and @enemiesCleared()
        @bossEvents.taunt2 = true
        @skeletonKing.sayWithDuration? 5.0, "You are beginning to annoy me, frail one."
        @timers.bossDelay = 8
      else if @bossEvents.taunt2 and not @bossEvents.wave3 and @timers.bossDelay <= 0
        @bossEvents.wave3 = true
        @timers.bossDelay = 8
        @spawnAndAggroUnit "brittle-skeleton", 81, 34, @hero
        @spawnAndAggroUnit "brittle-skeleton", 75, 23, @hero
        @spawnAndAggroUnit "brittle-skeleton", 83, 24, @hero
        @spawnAndAggroUnit "brittle-skeleton", 74, 31, @hero
        @spawnAndAggroUnit "brittle-skeleton-archer", 79, 29, @hero
      else if @bossEvents.wave3 and not @bossEvents.wave3_1 and @timers.bossDelay <= 0
        @bossEvents.wave3_1 = true
        @timers.bossDelay = 8
        @spawnAndAggroUnit "brittle-skeleton", 39, 32, @hero
        @spawnAndAggroUnit "brittle-skeleton", 45, 24, @hero
        @spawnAndAggroUnit "brittle-skeleton", 38, 25, @hero
        @spawnAndAggroUnit "brittle-skeleton", 46, 32, @hero
        @spawnAndAggroUnit "brittle-skeleton-archer", 42, 28, @hero
      else if @bossEvents.wave3_1 and not @bossEvents.wave3_2 and @timers.bossDelay <= 0
        @bossEvents.wave3_2 = true
        @timers.bossDelay = 8
        @skeletonKing.say? "Rise, my children, and protect me!"
        _.find(@waves, name: "archer-skeletons").scaledPower = 95.0
        @assignWaveRegion("archer-skeletons", "boss-top-left", new Rectangle(48, 51, 3.0, 3.0, 0))
        @spawnWaveNamed "archer-skeletons"
        _.find(@waves, name: "shaman-skeletons").scaledPower = 95.0
        @assignWaveRegion("shaman-skeletons", "boss-top-right", new Rectangle(70, 48, 3.0, 3.0, 0))
        @spawnWaveNamed "shaman-skeletons"
      else if @bossEvents.wave3_2 and not @bossEvents.wave3_3 and @timers.bossDelay <= 0
        @bossEvents.wave3_3 = true
        @timers.bossDelay = 8
        @skeletonKing.say? "Rise, my children, and protect me!"
        _.find(@waves, name: "archer-skeletons").scaledPower = 95.0
        @assignWaveRegion("archer-skeletons", "boss-bottom-left", new Rectangle(41, 26, 3.0, 3.0, 0))
        @spawnWaveNamed "archer-skeletons"
        _.find(@waves, name: "archer-skeletons").scaledPower = 95.0
        @assignWaveRegion("archer-skeletons", "boss-bottom-right", new Rectangle(79, 29, 3.0, 3.0, 0))
        @spawnWaveNamed "archer-skeletons"
      else if @bossEvents.wave3_3 and not @bossEvents.king and @timers.bossDelay <= 0
        @bossEvents.king = true
        @timers.bossDelay = 8
        @skeletonKing.say? "It would appear I have to do everything myself!"
        _.find(@waves, name: "shaman-skeletons").scaledPower = 95.0
        @assignWaveRegion("shaman-skeletons", "boss-top-left", new Rectangle(48, 51, 3.0, 3.0, 0))
        @spawnWaveNamed "shaman-skeletons"
        _.find(@waves, name: "shaman-skeletons").scaledPower = 95.0
        @assignWaveRegion("shaman-skeletons", "boss-top-right", new Rectangle(70, 48, 3.0, 3.0, 0))
        @spawnWaveNamed "shaman-skeletons"
        @skeletonKing.isAttackable = true
        @skeletonKing.attack @hero
      else if @bossEvents.king and not @bossEvents.son1 and @enemiesCleared()
        @actorEvents["raven-return-village"] = true
        @bossEvents.son1 = true
        @actors.son.setExists true
        @actors.son.pos.x = 47
        @actors.son.pos.y = 67
        @actors.son.moveXY 47, 52
        @world.setGoalState 'kill-skeleton-king', 'success'
      else if @bossEvents.son1 and not @bossEvents.son2 and @actors.son.pos.x is 47 and @actors.son.pos.y is 52
        @bossEvents.son2 = true
        pos = Vector.subtract(@actors.son.pos, @hero.pos).normalize().multiply(7).add(@hero.pos)
        @actors.son.moveXY pos.x, pos.y
      else if @bossEvents.son2 and not @bossEvents.sonDialog and @actors.son.pos.x >= (@hero.pos.x - 7) and @actors.son.pos.y >= (@hero.pos.y - 7)
        @bossEvents.sonDialog = true
        @timers.bossDelay = 3
        @actors.son.velocity.multiply 0
        @actors.son.setAction null
        @actors.son.setTarget null
        @actors.son.say? "Thank you for saving me! Let's return to the village!"
      else if @bossEvents.sonDialog and @timers.bossDelay <= 0 and not @bossEvents.returnVillage1
        @bossEvents.returnVillage1 = true
        @currentStack = 0
        @configureStack()
        @actors.raven.pos.x = 60.5
        @actors.raven.pos.y = 41
        @hero.pos.x = 36
        @hero.pos.y = 28
        @hero.rotation = 90
        @actors.son.pos.x = 28
        @actors.son.pos.y = 26
      else if @bossEvents.returnVillage1 and not @bossEvents.returnVillage2
        @bossEvents.returnVillage2 = true
        @actors.elder.say? "We are in forever in your debt, great champion. Many blessings!"
        
  spawnAndAggroUnit: (unit, x, y, target) ->
    u = @instabuild(unit, x, y)
    u.attack target
  
  populateTerrain: (boss) ->
    #
    # populateTerrain
    #   | clears terrain then either restores the current stacks terrain or generates new terrain if it's a new stack
    #
    if typeof boss is "undefined"
      boss = false
    
    for terrain, i in @terrainCleanupObjects
      terrain = (terrain.split('-').map (word) -> word[0].toUpperCase() + word[1..-1].toLowerCase()).join ' '
      objs = (t for t in @world.thangs when t.spriteName is terrain and t.exists)
      for obj, i in objs
        obj.setExists(false)
    
    if boss
      @terrainStack[@currentStack] = @bossStack
      @stackSpawns[@currentStack] = 0
      
    if typeof @terrainStack[@currentStack] isnt "undefined"
      for stack, i in @terrainStack[@currentStack]
        t = @instabuild(stack.obj, stack.x, stack.y)
        if typeof stack.r isnt "undefined"
          t.rotation = stack.r
          t.addTrackedProperties ['rotation', 'number']
          t.keepTrackedProperty 'rotation'
        if typeof stack.c isnt "undefined"
          t.cancelCollisions()
        t.stateless = false
    else
      # generate new random terrain
      stack = []
      r = Math.round(@world.rand.randf2(@maxNumTerrainObjects / 2, @maxNumTerrainObjects))
      for i in [1..r] by 1
        r2 = Math.round(@world.rand.randf2(0, @terrainObjects.length - 1))
        x = Math.round(@world.rand.randf2(15, 105))
        if @world.rand.randf() < 0.5
          y = Math.round(@world.rand.randf2(0, 15))
        else
          y = Math.round(@world.rand.randf2(45, 65))
        stack.push({obj: @terrainObjects[r2], x: x, y: y})
        t = @instabuild(@terrainObjects[r2], x, y)
        t.stateless = false
      
      # generate fire traps
      r = Math.round(@world.rand.randf2(0, @maxNumFireTraps))
      for i in [1..r] by 1
        x = Math.round(@world.rand.randf2(15, 105))
        y = Math.round(@world.rand.randf2(15, 55))
        stack.push({obj: "fire-trap", x: x, y: y})
        t = @instabuild("fire-trap", x, y)
        t.stateless = false
        
      @terrainStack.push(stack)
    @world.getSystem("AI").onObstaclesChanged()
  
  enemiesCleared: ->
    #
    # enemiesCleared
    #   | returns true if all skeletons are dead and all events have spawned for the current stack
    #
    units = (t for t in @world.thangs when t.isAttackable and t.team isnt "humans" and t.type isnt "sand-yak" and t.exists and not t.dead and t isnt @actors.raven and t isnt @hero)
    return units.length < 1 and @stackSpawns[@currentStack] is 0
  
  handleLevelWrap: ->
    #
    # handleLevelWrap
    #   | This handles the user wrapping from one side of the screen to another, ie changing stacks
    #
    if @enemiesCleared()
      if @leftWrapPending and @timers.wrapTimer <= 0
        @currentStack++
        if typeof @stackSpawns[@currentStack] is "undefined"
          @stackSpawns[@currentStack] = @numberOfEvents
        @actorEvents["raven-spawned"] = false
        @cleanUpYaks(true)
        @configureStack()
        if @hero.action is "move" and @hero.targetPos
          @hero.targetPos.x = 6
        @hero.pos.x = 6
        @leftWrapPending = false
      
      if @rightWrapPending and @timers.wrapTimer <= 0
        if @currentStack > 0
          @currentStack--
          @actorEvents["raven-spawned"] = false
          @cleanUpYaks(true)
          @configureStack()
          if @hero.action is "move" and @hero.targetPos
            @hero.targetPos.x = 115
          @hero.pos.x = 115
        @rightWrapPending = false
      
      # wrap from right edge of screen back to the left
      if @rectangles['wrap-point'].containsPoint(@hero.pos) and @timers.wrapTimer <= 0 and not @leftWrapPending and not @bossStackGenerated
        @timers.wrapTimer = 0
        @leftWrapPending = true
        
      # wrap from left edge of screen back to the right
      else if @rectangles['wrap-point2'].containsPoint(@hero.pos) and @timers.wrapTimer <= 0 and not @rightWrapPending
        @timers.wrapTimer = 0
        @rightWrapPending = true
  
  checkVictory: ->
    if @bossEvents.returnVillage2
      @setGoalState 'hero-survive', 'success'
  
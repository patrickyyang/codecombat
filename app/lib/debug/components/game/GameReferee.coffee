Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class GameReferee extends Component
  @className: 'GameReferee'
  isGameReferee: true
  HEROES: [
    "Captain", "Knight", "Samurai", "Raider", "Goliath", "Guardian", "Duelist", "Champion",
    "Forest Archer", "Trapper", "Ninja","Assassin", 
    "Librarian", "Potion Master", "Sorcerer", "Necromancer", "Master Wizard", "Pixie"]
  
  MELEES: ["Captain", "Knight", "Samurai", "Raider", "Goliath", "Guardian", "Duelist", "Champion"]
  RANGERS: ["Forest Archer", "Trapper", "Assassin", "Ninja"]
  WIZARDS: ["Librarian", "Potion Master", "Sorcerer", "Necromancer", "Master Wizard", "Pixie"]
  
  attach: (thang) ->
    super thang
    thang.stringGoals = []
    thang.addTrackedProperties ['stringGoals', 'array']

  initialize: ->
    @world.gameReferee = @
    # Temporary janky solution to default Hero Placeholder Components we don't want: delete them!
    for propertyToIgnore in [
      # 'pos'
      # 'rotation'
      # 'width'
      # 'height'
      'shape'
      'depth'
      'volume'
      # 'dragArea'
      'hasRotated'
      'rectangle'
      'ellipse'
      'getShape'
      # 'isGrounded'
      # 'isAirborne'
      'contains'
      'distance'
      'distanceSquared'
      'distanceTo'
      'distanceToValidateReturn'
      'getNearest'
      'findNearest'
      'intersects'
      'team'
      'superteam'
      'significantProperty'
      'getFriends'
      'findFriends'
      'hasFriends'
      'getCombatants'
      'findCombatants'
      'findCorpses'
      'getEnemies'
      'findEnemies'
      'hasEnemies'
      'getEnemyMissiles'
      'findEnemyMissiles'
      'getFriendlyMissiles'
      'findFriendlyMissiles'
      'getNearestFriend'
      'findNearestFriend'
      'getNearestEnemy'
      'findNearestEnemy'
      'getNearestEnemyValidateReturn'
      'getNearestCombatant'
      'findNearestCombatant'
      'allianceSystem'
      'allies'
      'allAllies'
      'attack'
    ]
      delete @[propertyToIgnore]

    # @spawnAliases = {
    #   "munchkin": ["munchkin-m","munchkin-f"],
    #   "soldier": ["soldier-m", "soldier-f"],
    #   "archer": ["archer-f", "archer-m"],
    #   "peasant": ["peasant-f", "peasant-m"],
    #   "scout": ["ogre-scout-f", "ogre-scout-m"],
    #   "forest": ["tree-stand-1","tree-stand-2","tree-stand-3","tree-stand-4","tree-stand-5","tree-stand-6"],
    #   "fir-forest": ["mountain-tree-stand-1","mountain-tree-stand-2","mountain-tree-stand-3","mountain-tree-stand-4"],
    #   "clump": ["desert-clump-0", "desert-clump-1", "desert-clump-2", "desert-clump-3"],
    #   "sand": ["sand-1", "sand-2", "sand-3", "sand-4", "sand-5", "sand-6"],
    #   "grass": ["grass-1", "grass-2", "grass-3", "grass-4", "grass-5", "grass-6"],
    #   "firn": ["firn-1", "firn-2", "firn-3", "firn-4", "firn-5", "firn-6"],
    #   "talus": ["talus-1", "talus-2", "talus-3", "talus-4", "talus-5", "talus-6"],
    #   "house": ["house-1", "house-2", "house-3", "house-4"],
    #   "forest-tree": ["choppable-tree-1", "choppable-tree-2", "choppable-tree-3", "choppable-tree-4"],
    #   "rock-cluster": ["rock-cluster-1", "rock-cluster-2", "rock-cluster-3"],
    #   "desert-house": ["desert-house-1", "desert-house-2", "desert-house-3", "desert-house-4"],
    #   "desert-rubble": ["desert-rubble-1", "desert-rubble-2", "desert-rubble-3"],
    #   "desert-palm": ["desert-palm-1", "desert-palm-2"],
    #   "fir-tree": ["fir-tree-1", "fir-tree-2", "fir-tree-3", "fir-tree-4"],
    #   "mountain-shrub": ["mountain-shrub-1", "mountain-shrub-2", "mountain-shrub-3", "mountain-shrub-4"],
    #   "forest-shrub": ["shrub-1", "shrub-2", "shrub-3"],
    #   "desert-shrub": ["desert-shrub-1", "desert-shrub-2"],
    #   "ice-crystals": ["ice-crystals-1","ice-crystals-2"],
    #   "frozen-figure": ["frozen-munchkin","frozen-soldier-m", "frozen-soldier-f"],
    #   "ice-house": ["igloo-1", "igloo-2", "igloo-3"],
    #   "crevasse": ["crevasse-1", "crevasse-2", "crevasse-3"],
    #   "barrel": ["barrel-1", "barrel-2"],
    #   "big-rocks": ["big-rocks-1", "big-rocks-2","big-rocks-3","big-rocks-4"]
    # }

    @validSpawnTypes = _.union(@buildTypes, _.keys(@spawnAliases))
    
    @actionHelpers = {}
    
    @goals = []
    @stringGoals = []
    @goalsCompleted = 0
    @numSpawns = 0
    @rand = @world.rand.rand
    @rand2 = @world.rand.rand2
    @randomInteger = (min, max) =>
      @world.rand.rand2 min, max+1
    @randomFloat = @world.rand.randf2
    Object.defineProperty(@, 'time', {
      get: () => @world.age,
      set: (x) => throw new Error("You can't set game.time")
    })
    Object.defineProperty(@, 'deltaTime', {
      get: () => @world.dt,
      set: (x) => throw new Error("You can't set game.deltaTime")
    })
    
    # Thangs which are added by non-player should be destroyable too because the player can get their reference throug events (collide for ex.)
    @attachMethodHelpers(thang) for thang in @world.thangs
    

    # This stuff makes the esper_property thing work properly.
    return unless aether = @world.userCodeMap['Hero Placeholder']?.plan  # TODO: fix the jank
    esperEngine = aether.esperEngine
    esperEngine.options.foreignObjectMode = 'smart'
    esperEngine.addGlobal 'game', @
    
    @db = { get: @db_get, add: @db_add, set: @db_set, world: @world }
    esperEngine.addGlobal 'db', @db
    # @ui = { track: @ui_track, _self: @ }
    # esperEngine.addGlobal 'ui', @ui
    esperEngine.addGlobal 'handler', @fn
    esper.SmartLinkValue.makeThreadPrivileged esperEngine.evaluator


  ##### Helpers #####

  reverseAlias: (str) ->
    return str if @spawnAliases[str]
    for key of @spawnAliases
      return key if @spawnAliases[key].indexOf(str) > -1
    str
  

  gameBuild: (type, x, y, isPlayer) ->
    toBuild = @buildables[type]
    @toBuild = toBuild
    @setTargetPos new Vector(x, y), 'spawnXY'
    if @toBuild.thangTemplate
      thang = @performBuild()
      return thang
    thangType = _.find(@world.thangTypes, original: toBuild.thangType)
    spriteName = thangType.name
    components = _.cloneDeep @componentsForThangType toBuild.thangType
    #if thangType.kind is 'Hero'  # TODO: just use this once the client code that provides this field is live
    if spriteName in @HEROES
      equipsConfig = _.find(components, (component) -> component[0].className is 'Equips')[1]
      attackableConfig = _.find(components, (component) -> component[0].className is 'Attackable')[1]
      attackableConfig.maxHealth = 250 * equipsConfig.maxHealthFactor
      if not _.find(components, (component) -> component[0].className is 'Attacks') and @world.classMap['Attacks']
        attackRange = 3
        if spriteName in @RANGERS or spriteName in @WIZARDS
          attackRange = 30
        attacks = [@world.classMap['Attacks'], {
          "attackDamage": (@attackDamage or 6) * equipsConfig.attackDamageFactor,
          "attackRange": attackRange,
          "cooldown": (@cooldown or 0.5),
          "specificCooldown": (@specificCooldown or 0),
          "attacksWhenOutOfRange": (@attacksWhenOutOfRange or false),
          "complainsWhenAttackingOutOfRange": (@complainsWhenAttackingOutOfRange or false),
          "chasesWhenAttackingOutOfRange": (@chasesWhenAttackingOutOfRange or true),
          "attackMass": (@attackMass or 5),
          "attackZAngle": (@attackZAngle or 0.1),
          "attackMovesIncrementally": (@attackMovesIncrementally or false)
        }]
        components.push attacks

      if spriteName in @MELEES and not _.find(components, (component) -> component[0].className is 'Cleaves') and @world.classMap['Cleaves']
        container = [@world.classMap['Cleaves'], {
          cooldown: 1,
          specificCooldown: 15,
          cleaveDamage: (@cleaveDamage or 15),
          cleaveAngle: 6.28,
          cleaveFriendlyFire: false,
          cleaveMass: 0,
          cleaveZAngle: 0.785,
          cleaveRange: 15
        }]
        components.push container
      
      if spriteName in ["Goliath"] and not _.find(components, (component) -> component[0].className is 'Stomps') and @world.classMap['Stomps']
        container = [@world.classMap['Stomps'], {
          cooldown: 1,
          specificCooldown: 15
        }]
        components.push container

      if not _.find(components, (component) -> component[0].className is 'Container') and @world.classMap['Container']
        container = [@world.classMap['Container'], {
          stackSize: (@stackSize or 1),
          sizeLimit: (@sizeLimit or false)
        }]
        components.push container
      
      if spriteName in @RANGERS or spriteName in @WIZARDS
        if not _.find(components, (component) -> component[0].className is 'Spawns') and @world.classMap['Spawns']
          spawns = [@world.classMap['Spawns'], {
            requiredThangTypes: []
          }]
          components.push spawns
        if spriteName in @RANGERS and @missileThangTypes?.arrow
          if not _.find(components, (component) -> component[0].className is 'Shoots') and @world.classMap['Shoots']
            shoots = [@world.classMap['Shoots'], {
              requiredThangTypes: [@missileThangTypes?.arrow]
            }]
            components.push shoots
        if spriteName in @WIZARDS and @missileThangTypes?.energy
          if not _.find(components, (component) -> component[0].className is 'Shoots') and @world.classMap['Shoots']
            shoots = [@world.classMap['Shoots'], {
              requiredThangTypes: [@missileThangTypes?.energy]
            }]
            components.push shoots
    thang = @performBuild undefined, spriteName, components
    # console.log(thang.maxHealth, thang.attackDamage, thang.maxSpeed)
    thang

  ##### Shareable Game APIs #####

  #debug: (str) ->
    #console.log str

  spawnXY: (type, x, y, isPlayer=false) ->
    if @numSpawns > @maxSpawnables
      throw new Error("Maximum spawns (#{@maxSpawnables}) exceeded.")
    if typeof type is 'undefined'
      throw new ArgumentError "You need something to spawn.", "spawnXY", "type", "string", type
    unless type and type in @validSpawnTypes
      throw new ArgumentError "You need a valid string to spawn.  See the full list of things you can spawn in the 'SPAWNABLE' section.", "spawnXY", "type", "string", type
    if not _.isNumber x
      throw new ArgumentError "Spawn the #{type} at an (x, y) coordinate.", "spawnXY", "x", "number", x
    if not _.isNumber y
      throw new ArgumentError "Spawn the #{type} at an (x, y) coordinate.", "spawnXY", "y", "number", y

    # Resolve aliases
    spawnType = type
    if aliases = @spawnAliases[type]
      type = @world.rand.choice(aliases)
    
    # Build the thang
    thang = @gameBuild type, x, y, isPlayer
    thang.type = spawnType unless thang.type
    
    
    # Coin reverse hook, lets return coins their true type.
    if type in ["bronze-coin", "silver-coin", "gold-coin"]
      thang.type = type
    
    return unless thang
    @numSpawns += 1
    
    # Hack for pets
    if thang.collisionCategory in ["dead", "pet"]
      thang.collisionCategory = "ground"
      thang.destroyBody?()
      thang.createBodyDef?()
      thang.createBody?()
      thang.updateRegistration()
    
    @attachMethodHelpers thang
    unless isPlayer
      thang.gameEntity = true
      @attachActionHelpers([thang])
      @attachPropertyHelpers thang
      # TODO: is there a better way to do this?
      @attachAI thang, "FearsTheLight" if type is 'skeleton'
      thang.trigger? "spawn"
    thang.commander = @

    if @proxifyThang
      thang = @proxifyThang thang
    thang

  spawnPlayerXY: (arg1, arg2, arg3) ->
    # Old style: spawnHeroXY(x, y)
    # New style: spawnHeroXY(type, x, y)
    if typeof(arg1) is 'string'
      type = arg1
      x = arg2
      y = arg3
    else
      x = arg1
      y = arg2
      type = arg3 or "captain"
    # TODO: Document third argument, add error handling
    if @world.player
      throw new Error("You can only spawn one player")
    player = @spawnXY type, x, y, true
    player.isPlayer = true
    @world.player = player
    player.on("click", @defaultClickHandler)
    player.on("keydown", @defaultKeydownHandler)
    player.on("keyheld", @defaultKeyheldHandler)
    # @attachScaleHelper player
    # @attachMovableHelper player
    # @attachMaxSpeedHelper player
    @attachPropertyHelpers player
    player
  
  spawnHeroXY: (args...) ->
    @spawnPlayerXY(args...)
  
  setActionFor: (thangOrType, event, fn) ->
    units = []
    if typeof(thangOrType) is "string"
      # TODO: check for valid types?
      @actionHelpers[thangOrType] ?= {}
      @actionHelpers[thangOrType][event] ?= []
      @actionHelpers[thangOrType][event].push(fn) unless @actionHelpers[thangOrType][event].indexOf(fn) > -1
      units = (u for u in @world.thangs when u.type is thangOrType)
    else if typeof(thangOrType) is 'object'
      units = [thangOrType]
    for unit in units when unit?.exists
      if not unit.on and not _.find(unit.components, (component) -> component?[0].className is 'HasEvents') and @world.classMap['HasEvents']
        unit.addComponents([@world.classMap['HasEvents'], {}])
        unit.updateRegistration()
      unit.on?(event, fn)
  
  setPropertyFor: (spawnType, key, value) ->
    if key in @esperProperties
      key = "esper_" + key
    for u in @world.thangs when u.type is spawnType
      u[key] = value
    f = (event) =>
      return if not event.target
      event.target[key] = value
    @setActionFor(spawnType, "spawn", f)
    if key is "maxHealth"
      @setPropertyFor(spawnType, "health", value)
  
  # should be moved in GameSpawns
  attachActionHelpers: (units) ->
    return unless units?.length
    for unit in units
      t = @reverseAlias unit.type
      if events = @actionHelpers?[t]
          for event in _.keys(events)
            if not unit.on and not _.find(unit.components, (component) -> component?[0].className is 'HasEvents') and @world.classMap['HasEvents']
              unit.addComponents([@world.classMap['HasEvents'], {}])
              unit.updateRegistration()
            unit.on(event, fn) for fn in events[event]


  addMoveGoalXY: (x, y) ->
    if not _.isNumber x
      throw new ArgumentError "Set the goal at an (x, y) coordinate.", "addMoveGoalXY", "x", "number", x
    if not _.isNumber y
      throw new ArgumentError "Set the goal at an (x, y) coordinate.", "addMoveGoalXY", "y", "number", y

    mark = @spawnXY('x-mark-red', x, y)
    @addGoal("move", { pos: Vector(x,y), mark: mark } )
    return

  addDefeatGoal: (amount) ->
    if amount and amount < 0
      amount = 0
    @addGoal("defeat", { team: ["ogres","neutral"] , amount: amount })
    return

  addSurviveGoal: (timeOrType) ->
    if typeof(timeOrType) is 'number' and timeOrType > 0
      @addGoal("survive", { seconds: timeOrType } )
      if not @programmableProperties or "ui.track" not in @programmableProperties
        Object.defineProperty(@, 'timeToSurvive', {
          get: () => if timeOrType > @world.age then timeOrType - @world.age else 0,
          set: (x) => throw new Error("You can't set game.timeToSurvive")
        })
        @ui_track?(@, "timeToSurvive")
      return 
    if typeof(timeOrType) is 'string'
      @addGoal("survive", { type: timeOrType } )
      return
    @addGoal("survive", { seconds: null } )
    return

  addCollectGoal: (amount) ->
    unless !amount or (typeof(amount) is 'number')
      throw new ArgumentError "Do not enter an argument if the goal is to collect all items. Otherwise, enter a number that equals how many items the player needs to collect.", "addCollectGoal", "amount"
    amount = 0 if amount and amount < 0
    @addGoal("collect", { types: ['Gem', 'Chest of Gems', 'Locked Chest', "Bronze Coin", "Silver Coin", "Gold Coin"], amount: amount } )
    return
    
  addManualGoal: (description) ->
    goal = @addGoal('manual', { description })
    return goal
    
  addScoreGoal: (amount) ->
    unless _.isNumber(amount)
      throw new ArgumentError "How many score points are required for the goal?", "addScoreGoal", "amount"
    @addGoal("score", {amount: amount } )
    return
  
  setBehavior: (target, behaviorString) ->
    unless target.type in ["munchkin", "soldier"]
      throw new Error "Only units can have behaviors. Did you mean to use any of : " + ["munchkin", "soldier"]
    unless behaviorString in ["attackNearest"]
      throw new Error "Unknown behavior string: " + behaviorString + ". Did you mean to use any of: " + ["attackNearest"]
    switch behaviorString
      when "attackNearest"
        target.commander = null
    
  addGoal: (goalType, config={}) ->
    # TODO: Type and Config check
    goal = type: goalType, success: false, config: config
    Object.defineProperty(goal, 'esper_success', {
      enumerable: true,
      get: () -> @success,
      set: (success) ->
        return if success is undefined
        unless _.isBoolean(success)
          throw new Error "success must be a boolean."
        @playerChangedSuccessTo = success
    })
    @goals.push goal
    stringGoal = _.pick(goal, ['type', 'success'])
    stringGoal.config = _.pick(goal.config, ['description','amount', 'seconds'])
    stringGoal = JSON.stringify(stringGoal)
    @stringGoals.push stringGoal
    @keepTrackedProperty 'stringGoals'
    return goal
  
  esper_setGoalState: (goal, success) ->
    unless typeof(goal) is "object" and goal.type
      throw new ArgumentError "The `goal` parameter should be a goal object", "setGoalState", "goal", "object", goal
    unless _.isBoolean(success)
      throw new ArgumentError "The `success` parameter should be a boolean", "setGoalState", "success", "boolean", success
    unless goal in @goals and goal.type is "manual"
      throw new Error "There is no such goal. Are you sure that you defined it with game.addManualGoal?"
    return if goal.success
    goal.success = success
    if goal.success
      @goalsCompleted++
    else
      @setGoalState('win-game', 'failure')
      @world.endWorld(false, 1.5)

  ##### Input Handling #####
  #### DEPRECATED (moved) ####

  defaultPlayerClickHandler: (event) ->
    player = event.target
    if event.type is 'click'
      target = event.target.world.getThangByID event.thangID
      if target and target.team isnt player.team and target.health > 0
        player.attack? target
      else
        world = event.target.world
        nearby = (u for u in world.thangs when not u.isPlayer and u.team isnt world.player.team and u.isAttackable and u.health > 0 and u.pos.distanceSquared(event.pos) <= 4)
        if nearby.length > 0
          console.log "NEAR CLICK ATTACK!!"
          player.attack? nearby[0]
        else
          player.move event.pos

  defaultPlayerKeydownHandler: (event) ->
    #console.log "keydown", event.keyCode, event.ctrlKey, event.metaKey, event.shiftKey, event.time
    player = event.target

    if event.keyCode == 32 or event.keyCode == 67
      # 32 = space, 67 = c
      if player.isReady?("cleave")
        player.cleave?()
      else
        player.sayWithoutBlocking "..."

  defaultPlayerKeyheldHandler: (event) ->
    player = event.target
    world = player.world
    #console.log "keyheld", event.keyCode, event.ctrlKey, event.metaKey, event.shiftKey, event.time, world.age
    # w = 87 , s= 83, a = 65 , d = 68
    
    player.inputVector ?= new Vector(0, 0)
    speed = player.maxSpeed / 10
    if event.keyCode == 83
      #console.log "s key"
      player.inputVector.add(new Vector(0, -speed))
    else if event.keyCode == 87
      #console.log "w key"
      player.inputVector.add(new Vector(0, speed))
    else if event.keyCode == 65
      #console.log "a key"
      player.inputVector.add(new Vector(-speed, 0))
    else if event.keyCode == 68
      #console.log "d key"
      player.inputVector.add(new Vector(speed, 0))
    
  ##### Game Logic #####
  update: ->
    if @world.player?.inputVector
      moveTo = @world.player.pos.copy().add(@world.player.inputVector)
      @world.player.inputVector = null
      @world.player.move(moveTo)

    for thang in @world.thangs when thang.trigger?
      thang.trigger "update", { deltaTime: @world.dt }
    @checkGoals() if @goals.length

  checkGoals: ->
    return if @goals.length is 0
    for goal in @goals
      continue if goal.success
      @goalHandler(goal)
    if @goalsCompleted == @goals.length
      @trigger? "victory" unless @readyWin
      @readyWin ?= @world.age
    if @readyWin + 1.5 <= @world.age # 3-second padding so victory event can be processed and look nice
      @world.endWorld true, 1.5
      @setGoalState 'win-game', 'success'

  goalHandler: (goal) ->
    switch goal.type
      when 'move'
        if @world.player?.distanceSquared(goal.config.pos) < 1
          goal.config.mark?.setExists false if goal.config.mark
          goal.success = true
          @goalsCompleted++
      when 'time'
        if @world.age >= goal.config
          goal.success = true
          @goalsCompleted++
      when 'survive', 'live'
        if @world.player?.health <= 0
          @setGoalState 'win-game', 'failure'
          @world.endWorld false, 1.5
        if goal.config?.type
          survivors = (thang for thang in @world.thangs when thang.type is goal.config.type and thang.exists and thang.health > 0)
          if survivors.length is 0
            @setGoalState 'win-game', 'failure'
            @world.endWorld false, 1.5
        if goal.config?.seconds and @world.age > goal.config.seconds
          # If a time is given, survive for that amount of time.
          goal.success = true
          @goalsCompleted++
        else if @goals.length > 1 and @goalsCompleted is (@goals.length - 1)
          # No time is given, survive until all other goals are complete.
          goal.success = true
          @goalsCompleted++
      when 'defeat'
        teams = if goal.config?.team then goal.config.team else ["ogres","neutral"]
        aliveDefeatables = (thang for thang in @world.thangs when thang.team in teams and thang.exists and thang.isAttackable and thang.health and thang.health > 0 and not thang.dead).length
        defeated = (thang for thang in @world.thangs when thang.team in teams and thang.health <= 0 and thang.exists and thang.dead).length
        amount = goal.config?.amount
        if (amount and defeated >= amount) or (not amount and aliveDefeatables is 0)
          goal.success = true
          @goalsCompleted += 1
      when 'collect', 'collect-gems'
        needToCollect = (thang for thang in @world.thangs when thang.spriteName in goal.config.types)
        # notCollected = (thang for thang in @world.thangs when thang.spriteName in goal.config.types and thang.exists and not thang.killer)
        collected = (thang for thang in @world.thangs when thang.spriteName in goal.config.types and not thang.exists and thang.killer).length
        amount = goal.config?.amount or needToCollect.length
        if needToCollect.length > 0 and collected >= amount
          goal.success = true
          @goalsCompleted += 1
      when 'score'
        if @score and @score >= goal.config.amount
          goal.success = true
          @goalsCompleted += 1
      when 'manual'
        # Old manual goal setting <Legacy>
        if goal.playerChangedSuccessTo?
          @esper_setGoalState(goal, goal.playerChangedSuccessTo)
          
          
          
  #### DB Stuff
  db_add: (key, value) ->
    return if key in ['add','get','set','world']
    console.log "DB ADD"
    # TODO: check arguments for validity and throw errors
    @world.keyValueDb ?= {}
    console.log(JSON.stringify(@world.keyValueDb))
    @world.keyValueDb[key] ?= 0
    @world.keyValueDb[key] += value
    @[key] ?= 0
    @[key] += value
    
  db_set: (key, value) ->
    return if key in ['add', 'get', 'set', 'world']
    console.log "DB SET", key, value
    # TODO: check arguments for validity and throw errors
    @world.keyValueDb ?= {}
    @world.keyValueDb[key] = value
    @[key] = value
    console.log(JSON.stringify(@world.keyValueDb))

    
  db_get: (key) ->
    # TODO: check arguments for validity and throw errors
    #console.log "DB GET", JSON.stringify(@world.keyValueDb) # Commented out because of the spam from custom property getting in ui_track
    return @world.keyValueDb?[key]
  
  
  
Component = require 'lib/world/component'

module.exports = class SarvenTreasureReferee extends Component
  @className: 'SarvenTreasureReferee'
  chooseAction: ->
    @configure()
    @decrementTimers()
    @updateCoinCounts()
    @handleTeleports()
    @spawnEventCoins()
  
  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    
    @disableEnemies = false
    
    @timers =
      "coinSpawn": 0
      "wrapCooldown": 0
    
    @currentCoins =
      "left": 0
      "middle": 0
      "right": 0
    
    @maxCoins = 
      "left": 10
      "middle": 20
      "right": 10
    
    @coinValues =
      "bronze-coin": 1
      "silver-coin": 2
      "gold-coin": 3
    
    @wrapPending = false
    
    @heroGold = 0
    @coinCooldown = 0.65
    @startGold = 0
  
  configure: ->
    return unless not @configured
    if not @disableEnemies
      @spawnWaveNamed "enemies"
      @spawnWaveNamed "headhunters"
    @configured = true
  
  decrementTimers: ->
    for name, timer of @timers
      @timers[name] -= @world.dt
  
  updateCoinCounts: ->
    leftCoins = (t for t in @world.thangs when (t.spriteName is "Gold Coin" or t.spriteName is "Silver Coin" or t.spriteName is "Bronze Coin") and t.exists and t isnt @hero and @rectangles["coins-left"].containsPoint t.pos)
    middleCoins = (t for t in @world.thangs when (t.spriteName is "Gold Coin" or t.spriteName is "Silver Coin" or t.spriteName is "Bronze Coin") and t.exists and t isnt @hero and @rectangles["coins-middle"].containsPoint t.pos)
    rightCoins = (t for t in @world.thangs when (t.spriteName is "Gold Coin" or t.spriteName is "Silver Coin" or t.spriteName is "Bronze Coin") and t.exists and t isnt @hero and @rectangles["coins-right"].containsPoint t.pos)
    @currentCoins.left = leftCoins.length
    @currentCoins.middle = middleCoins.length
    @currentCoins.right = rightCoins.length
  
  spawnEventCoins: ->
    if @timers.coinSpawn <= 0
      buildLeft = @spawnCoin('left')
      buildMiddle = @spawnCoin('middle')
      buildRight = @spawnCoin('right')
      
      if buildLeft or buildMiddle or buildRight
        @timers.coinSpawn = @coinCooldown
  
  spawnCoin: (location) ->
    if @currentCoins[location] < @maxCoins[location]
        buildType = @pickCoinType()
        buildp = @pickPointFromRegions([@rectangles['coins-' + location]])
        @currentCoins[location] += 1
        @instabuild(buildType, buildp.x, buildp.y)
    return buildp? false
  
  pickCoinType: ->
    r = @world.rand.randf()
    if r < .65
      return 'bronze-coin'
    else if r < .85
      return 'silver-coin'
    else
      return 'gold-coin'
  
  handleTeleports: ->
    if @wrapPending
      if not @hero.teleport
        @hero.teleport ?= true
        @hero.addTrackedProperties ['teleport', 'boolean']
        @hero.keepTrackedProperty 'teleport'
      rect = {
        'top-left': 'teleport-bottom-right'
        'top-right': 'teleport-bottom-left'
        'bottom-left': 'teleport-top-right'
        'bottom-right': 'teleport-top-left'
      }[@wrapPending]
      newPos = @pickPointFromRegions [@rectangles[rect]]
      @hero.pos = newPos
      @wrapPending = false
      if @hero.action in ["move", "idle"]
        @hero.endCurrentPlan()
      @timers.wrapCooldown = 3
      
    if @rectangles["teleport-top-left"].containsPoint(@hero.pos) and @timers.wrapCooldown <= 0
      @wrapPending = 'top-left'
    else if @rectangles["teleport-top-right"].containsPoint(@hero.pos) and @timers.wrapCooldown <= 0
      @wrapPending = 'top-right'
    else if @rectangles["teleport-bottom-left"].containsPoint(@hero.pos) and @timers.wrapCooldown <= 0
      @wrapPending = 'bottom-left'
    else if @rectangles["teleport-bottom-right"].containsPoint(@hero.pos) and @timers.wrapCooldown <= 0
      @wrapPending = 'bottom-right'
  
  checkVictory: ->
    if @hero.health <= 0
      @setGoalState 'survive', 'failure'
    else if @hero.gold >= 150
      @setGoalState 'survive', 'success'
      @setGoalState 'collect-gold', 'success'
    
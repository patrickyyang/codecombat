Component = require 'lib/world/component'

module.exports = class BackwoodsTreasureReferee extends Component
  @className: 'BackwoodsTreasureReferee'

  chooseAction: ->
    if @rectangles['bottom_room'].containsPoint @hero.pos
      if not @events.bottom_room_spawned
        @events.bottom_room_spawned = @world.age
        @events.bottom_gold = @startGold
        @spawnEvent 'bottom_room'
    if @rectangles['top_room'].containsPoint @hero.pos
      if not @events.top_room_spawned
        @events.top_room_spawned = @world.age
        @events.top_gold = @startGold
        @spawnEvent 'top_room'
    if @rectangles['left_room'].containsPoint @hero.pos
      if not @events.left_room_spawned
        @events.left_room_spawned = @world.age
        @events.left_gold = @startGold
        @spawnEvent 'left_room'
    @spawnEventCoins()

  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'

    @events =
      'bottom_room_spawned': false
      'top_room_spawned': false
      'left_room_spawned': false
      'bottom_gold': 0
      'top_gold': 0
      'left_gold': 0

    @lastCoinSpawn = @world.age
    @coinCooldown = 1.00
    @startGold = 20
    @maxGold = 70
    @coinValues =
      'bronze-coin': 1
      'silver-coin': 2
      'gold-coin': 3

  spawnEvent: (event) ->
    @spawnEventWaves event

  spawnEventWaves: (event) ->
    if event is 'bottom_room'
      @spawnWaveNamed 'all_munchkins_baseline'
      @spawnWaveNamed 'all_munchkins'
    if event is 'top_room'
      @spawnWaveNamed 'all_ogres_baseline'
      @spawnWaveNamed 'all_ogres'
    if event is 'left_room'
      @spawnWaveNamed 'all_throwers_baseline'
      @spawnWaveNamed 'all_throwers'

  spawnEventCoins: ->
    buildType = @pickCoinType()

    if @rectangles['bottom_room'].containsPoint @hero.pos
      event = 'bottom_room'
    if @rectangles['top_room'].containsPoint @hero.pos
      event = 'top_room'
    if @rectangles['left_room'].containsPoint @hero.pos
      event = 'left_room'

    if event
      if (@world.age - @lastCoinSpawn >= @coinCooldown)
        if event is 'bottom_room'
          # bottom room
          return if @events.bottom_gold > @maxGold
          buildp = @pickPointFromRegions([ @rectangles['bottom_spawn'] ])
          @events.bottom_gold += @coinValues[buildType]
        else if event is 'top_room'
          # top room
          return if @events.top_gold > @maxGold
          buildp = @pickPointFromRegions([
            @rectangles['top_spawn1']
            @rectangles['top_spawn2']
            @rectangles['top_spawn3']
          ])
          @events.top_gold += @coinValues[buildType]
        else if event is 'left_room'
          # left room
          return if @events.left_gold > @maxGold
          buildp = @pickPointFromRegions([
            @rectangles['left_spawn1']
            @rectangles['left_spawn2']
            @rectangles['left_spawn3']
          ])
          @events.left_gold += @coinValues[buildType]

        if buildp
          @instabuild(buildType, buildp.x, buildp.y)
          @lastCoinSpawn = @world.age

  pickCoinType: ->
    r = @world.rand.randf()
    if r < .65
      return 'bronze-coin'
    else if r < .85
      return 'silver-coin'
    else
      return 'gold-coin'

  checkVictory: ->
    if @hero.gold >= 100
        @setGoalState 'collect-gold', 'success'

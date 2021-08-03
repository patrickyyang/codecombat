Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class MadMaxerGetsGreedyReferee extends Component
  @className: 'MadMaxerGetsGreedyReferee'
  chooseAction: ->
    @spawnCoins()
    @despawnCoins()

  setUpLevel: ->
    @victoryChecked = false
    @endTime = 25
    @spawnTime = @world.age + 1
    @despawnDelay = 5
    @spawnDelay = 1
    # This doesn't include golds. (See spawnCoins())
    @ctypes = [
      'bronze-coin',
      'bronze-coin',
      'bronze-coin',
      'silver-coin',
      'silver-coin',
    ]
    @cloneTargetCoin = null
    @playerCoins = []
    @cloneCoins = []

  spawnCoins: ->
    return if not @ctypes
    return if @world.age > @endTime
    return if @world.age < @spawnTime
    @despawnTime = @world.age + @calcDespawnDelay()
    @spawnTime = @world.age + @calcDespawnDelay() + @spawnDelay

    while (@playerCoins.length > 0)
      @playerCoins.pop()
    while (@cloneCoins.length > 0)
      @cloneCoins.pop()

    for ct in @ctypes
      @spawnMirror(ct, @pickPointFromRegions([@rectangles.playerField]))
    # Spawn one gold at the top of the field and one at the bottom. A greedy plan have to walk the length of the field every time.
    @spawnMirror('gold-coin', @pickPointFromRegions([@rectangles.goldTop]))
    @spawnMirror('gold-coin', @pickPointFromRegions([@rectangles.goldBottom]))

  spawnMirror: (ct, pp) ->
      # Spawn 2 coins, one on the player's side and one on the clone's side, in mirror positions.
      pfMinX = @rectangles.playerField.vertices()[0].x
      cfMaxX = @rectangles.cloneField.vertices()[2].x
      cp = new Vector(cfMaxX - (pp.x - pfMinX), pp.y)
      pcoin = @instabuild ct, pp.x, pp.y
      @playerCoins.push(pcoin)
      ccoin = @instabuild ct, cp.x, cp.y
      @cloneCoins.push(ccoin)

  despawnCoins: ->
    return if @world.age > @endTime
    return if @world.age < @despawnTime
    for c in @playerCoins when c.exists
      c.setExists(false)
    for c in @cloneCoins when c.exists
      c.setExists(false)
    while (@playerCoins.length > 0)
      @playerCoins.pop()
    while (@cloneCoins.length > 0)
      @cloneCoins.pop()
    @spawnTime = @world.age + @spawnDelay
    @despawnTime = @world.age + @spawnDelay + @calcDespawnDelay()

  checkVictory: ->
    return if @victoryChecked
    return if @world.age < @endTime
    return if (c for c in @built when c.exists and @endsWith(c.type, 'coin')).length > 0
    playerGold = @world.getSystem('Inventory').teamGold.humans.gold
    cloneGold = @world.getSystem('Inventory').teamGold.ogres.gold
    if playerGold > cloneGold
      @setGoalState 'collect-coins', 'success'
    else
      @setGoalState 'collect-coins', 'failure'
    @victoryChecked = true
    @world.endWorld true, 1

  calcDespawnDelay: ->
    return @despawnDelay * (8.0 / @hero.maxSpeed)

  endsWith: (s, t) ->
    return s.indexOf(t, s.length - t.length) != -1

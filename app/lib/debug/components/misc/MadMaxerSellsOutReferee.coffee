Component = require 'lib/world/component'

module.exports = class MadMaxerSellsOutReferee extends Component
  @className: 'MadMaxerSellsOutReferee'
  chooseAction: ->
    @spawnRing()
    @killRing()

  setUpLevel: ->
    @targetGold = 100
    @victoryChecked = false
    @waves = 0
    @baseMaxSpeed = 8 # Speed of Anya/Tharin with basic Leather Boots
    @runDeadline = 6
    @spawnDelay = 6

    # these will be assigned such that a naive route will reach the golds as INefficiently as possible.
    @ctypes = [
      'bronze-coin'
      'bronze-coin'
      'gold-coin'
      'gold-coin'
      'bronze-coin'
      'gold-coin'
    ]

    # Create spawn points
    nc = @ctypes.length
    hp = @points.spawnCenter
    r = 12
    @coinSpawns = []
    for i in [0...nc]
      a = (2*Math.PI)/nc * i
      x = hp.x + r * Math.cos(a)
      y = hp.y + r * Math.sin(a)
      p = new Vector(x, y)
      @coinSpawns.push(p)

  spawnRing: ->
    return if @ctypes is null
    return if @world.age > 30
    return if @world.age < @spawnTime
    @killTime = @world.age + @runDeadline * (@baseMaxSpeed / @hero.maxSpeed)
    @spawnTime = @killTime + @spawnDelay

    spawners = []
    for i in [0...@coinSpawns.length]
      spawners.push({
        'type': null,
        'point': @coinSpawns[i],
        'dist': @hero.distanceTo(@coinSpawns[i])
      })

    # sort spawns by distance from hero, from furthest to nearest.
    spawners.sort (a,b) ->
      return if a.dist >= b.dist then -1 else 1
    # interleave spawn points to generate the most INefficient route.
    t = spawners.splice(5, 1)[0]
    spawners.splice(1, 0, t)
    t = spawners.splice(5, 1)[0]
    spawners.splice(3, 0, t)
    t = spawners.splice(5, 1)[0]
    spawners.splice(4, 0, t)
    #for i in [0...spawners.length]
    #  console.log("" + i + ": " + (if spawners[i] then spawners[i].dist else 'uhoh'))

    # assign coin types to the interleaved slots.
    for i in [0...spawners.length]
      spawners[i].type = @ctypes[i]

    # Spawn something already!
    for i in [0...spawners.length]
      type = spawners[i].type
      p = spawners[i].point
      coin = @instabuild type, p.x, p.y
      
    ++@waves

  killRing: ->
    return if @ctypes is null
    return if @world.age < @killTime
    @spawnTime = @world.age + @spawnDelay
    @killTime = @spawnTime + @runDeadline
    for coin in @built when coin.exists and coin.type is 'coin'
      coin.setExists(false)

  endsWith: (s, t) ->
    return s.indexOf(t, s.length - t.length) != -1

  checkVictory: ->
    return if @victoryChecked
    return if @world.age < 30
    goldCoins = (c for c in @built when c.exists and c.type is 'coin' and c.value == 3)
    return if goldCoins.length > 0
    totalGoal = @waves * 9
    if @world.getSystem('Inventory').teamGold.humans.gold >= totalGoal
      @victoryChecked = true
      @setGoalState 'get-coins', 'success'
      @world.endWorld true, 1
    else
      @victoryChecked = true
      @setGoalState 'get-coins', 'failure'
      @world.endWorld true, 1

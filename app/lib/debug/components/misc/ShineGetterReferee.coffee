Component = require 'lib/world/component'

module.exports = class ShineGetterReferee extends Component
  @className: 'ShineGetterReferee'
  chooseAction: ->
    @shineGetterSpawnCoins()

  setUpLevel: ->
    @targetGold = 100
    @respawnDistance = 6

    ctypes = [
      'bronze-coin'
      'silver-coin'
      'bronze-coin'
      'bronze-coin'
      'bronze-coin'
      'silver-coin'
      'bronze-coin'
      'bronze-coin'
      'silver-coin'
      'gold-coin'
      'gold-coin'
      'gold-coin'
    ]
    # rotate the list.
    n = @world.rand.rand(ctypes.length)
    ctypes = ctypes.slice(n, ctypes.length).concat(ctypes.slice(0, n))
    console.log('' + n + ': ' + ctypes.length)

    # Set up spawn points in a ring around the hero.
    hp = @hero.pos
    r = 12
    @coinSpawns = []
    for i in [0...12]
      a = (2*Math.PI)/12 * i
      x = hp.x + r * Math.cos(a)
      y = hp.y + r * Math.sin(a)
      p = new Vector(x, y)
      t = ctypes[i]
      @coinSpawns.push({ 'id':i, 'pos':p, 'type':t, 'coin':null })

  shineGetterSpawnCoins: ->
    for c in @coinSpawns
      if not c.coin
        if @hero.distanceTo(c.pos) > @respawnDistance
          c.coin = @shineGetterSpawnCoin(c)
      if c.coin and not c.coin.exists
        c.coin = null

  shineGetterSpawnCoin: (cinfo) ->
    coin = @instabuild cinfo.type, cinfo.pos.x, cinfo.pos.y
    return coin

  checkVictory: ->
    if @world.getSystem('Inventory').teamGold.humans.gold >= @targetGold
      @setGoalState 'collect-gold', 'success'
      @world.endWorld true, 1

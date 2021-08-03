Component = require 'lib/world/component'

module.exports = class TheDunesReferee extends Component
  @className: 'TheDunesReferee'
  chooseAction: ->
    # TODO: build sand-yak, ogre-m, ogre-munchkin-m, ogre-munchkin-f, ogre-thrower, bronze-coin, silver-coin, gold-coin
    # The units go past, hero fights some but not others, grabs coins if no enemy to fight.
    @setUpTheDunes() unless @theDunesSetUp
    @spawnCoin()
    @spawnMinion()
    @controlMinions()
    @checkTheDunesVictory()

  setUpTheDunes: ->
    @theDunesSetUp = true
    @coinBounds = x: 14, y: 8, width: 50, height: 25
    @minionStart = x: 0, y: 40
    @nextWaveTime = 1
    @waveTimeMin = 5
    @waveTimeMax = 7
    @spawns = [
      'ogre-thrower',
      'ogre-thrower',
      'ogre-thrower',
      'burl',
      'sand-yak',
      'sand-yak',
    ]
    # shuffle the list
    for i in [@spawns.length-1..1]
      j = Math.floor @world.rand.randf() * (i - 1)
      t = @spawns[j]
      @spawns[j] = @spawns[i]
      @spawns[i] = t
    # finish with a big ogre
    @spawns.push 'ogre-m'

  spawnCoin: ->
    return if @world.rand.randf() > 2 * @world.dt  # Don't build all the time, that would be too many coins.
    return if @world.age > 30  # Stop building coins after 30 seconds.
    spawnChances = [
      [0, 'bronze-coin']
      [65, 'silver-coin']
      [85, 'gold-coin']
    ]
    r = @world.rand.randf()
    n = 100 * Math.pow r, 20 / (@world.age + 1)
    for [spawnChance, type] in spawnChances
      if n >= spawnChance
        buildType = type
      else
        break
    @build buildType
    built = @performBuild()
    xOfs = @world.rand.randf() * @coinBounds.width
    if xOfs < @coinBounds.width / 2
      maxYOfs = xOfs
    else
      maxYOfs = @coinBounds.width - xOfs
    built.pos.x = @coinBounds.x + xOfs
    built.pos.y = @coinBounds.y + @world.rand.randf() * maxYOfs  # Triangle to fit within pillars
    built.addTrackedProperties ['pos', 'Vector']
    built.keepTrackedProperty 'pos'
    
  spawnMinion: ->
    return if @world.age < @nextWaveTime
    return if @spawns.length == 0
    @nextWaveTime = @world.age + (@waveTimeMin + @world.rand.randf() * (@waveTimeMax - @waveTimeMin))
    buildType = @spawns.shift()
    @buildXY buildType, @minionStart.x, @minionStart.y + 4 * (0.5 - @world.rand.randf())
    thang = @performBuild()
    thang.move x: thang.pos.x + 100, y: thang.pos.y
    if thang.type is 'sand-yak'
      thang.currentSpeedRatio = 0.25 + 0.5 * @world.rand.randf()
      thang.scaleFactor = 0.25 + 1.5 * @world.rand.randf()
      thang.keepTrackedProperty 'scaleFactor'
        
  controlMinions: ->
    hero = @world.getThangByID 'Hero Placeholder'
    for minion in @built when minion.team
      if minion.pos.x > 82
        minion.setExists false
      else if hero.dead
        minion.move x: @minionStart.x + 100, y: @minionStart.y
      else if minion.team is 'ogres' and minion.canSee(hero) or minion.hadSeenHero
        minion.hadSeenHero = true
        if minion.type is 'thrower' and minion.pos.x < 32
          minion.move {x: 32, y: minion.pos.y}
        else
          minion.attack hero
          minion.specificAttackTarget = hero

  checkTheDunesVictory: ->
    return if @victoryChecked
    return if @world.age < 30
    ogresSurviving = (t for t in @world.thangs when t.team is 'ogres' and t.exists and t.health > 0).length
    coinsLeft = @world.getSystem('Inventory').collectables.length
    if (not coinsLeft and not ogresSurviving) or @world.age > 59
      @victoryChecked = true
      @setGoalState 'collect-coins', 'success' unless coinsLeft
      @setGoalState 'ogres-die', 'success' unless ogresSurviving
      @world.endWorld true, 1

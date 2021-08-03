Component = require 'lib/world/component'

module.exports = class DeadlyPursuitReferee extends Component
  @className: 'DeadlyPursuitReferee'

  chooseAction: ->
    @setUpDeadlyPursuit() unless @deadlyPursuitSetUp
    # Build a coin, unless we've built all of them.
    @spawnCoin()

    t = @world.age
    # Maybe build an ogre
    @spawnOgre()
    
    @controlMinions()

    @checkDeadlyPursuitVictory()

  setUpDeadlyPursuit: ->
    @deadlyPursuitSetUp = true
    @spawnLocations = [
      {x: 26, y: 0}
      {x: 36, y: 135}
      {x: 41, y: 0}
      {x: 52, y: 135}
      {x: 56, y: 0}
      {x: 67, y: 135}
      {x: 72, y: 0}
      {x: 83, y: 135}
      {x: 88, y: 0}
      {x: 99, y: 135}
      {x: 105, y: 0}
      {x: 115, y: 135}
      {x: 123, y: 0}
    ]
    @delayedSpawns = []

  spawnCoin: ->
    return if @world.rand.randf() < 0.5  # Don't build all the time, that would be too many coins.
    return if @built?.length and @built[@built.length - 1].pos.x > 154  # Only build out to 154.
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
    built.pos.x = Math.min 155, 21 + @world.frames.length / 2 + (-0.5 + @world.rand.randf()) * 2
    built.pos.y = 66 + 8 * Math.sin(@world.frames.length * Math.PI / 30) + (-0.5 + @world.rand.randf()) * 2
    built.addTrackedProperties ['pos', 'Vector']
    built.keepTrackedProperty 'pos'
    
  spawnOgre: ->
    hero = @world.getThangByID 'Hero Placeholder'
    for spawn in @delayedSpawns when not spawn.spawned
      spawn.delay -= @world.dt
      if spawn.delay <= 0
        spawn.spawned = true
        @buildXY spawn.buildType, spawn.pos.x, spawn.pos.y
        thang = @performBuild()
        thang.attack hero
    spawnLocation = @spawnLocations[0]
    return unless spawnLocation and hero.pos.x > spawnLocation.x + 20
    @spawnLocations.shift()
    return if @spawnLocations.length < 12 and @world.rand.randf() < 0.5  # Only spawn some of the time (but always on the first one)
    @spawnLocations.shift()  # Never do two in a row
    nOgres = 1 + @world.rand.rand 3
    for i in [0 ... nOgres]
      spawnChances = [
        [0, 'ogre-thrower']
        [50, 'ogre-m']
        [75, 'ogre-shaman']
      ]
      n = @world.rand.rand 100
      for [spawnChance, type] in spawnChances
        if n >= spawnChance
          buildType = type
        else
          break
      if i is 0
        buildType = 'ogre-m'  # Make sure the slow one comes out first so the playe has enough warning.
      if i is 2 and buildType is 'ogre-m'
        buildType = 'ogre-shaman'  # Don't do three medium ogres, they might not all die.
      spawnDelay = {'ogre-thrower': 5.25, 'ogre-m': 0, 'ogre-shaman': 5}[buildType]
      if spawnDelay
        @delayedSpawns.push buildType: buildType, pos: spawnLocation, delay: spawnDelay
      else
        @buildXY buildType, spawnLocation.x, spawnLocation.y
        thang = @performBuild()
        
  controlMinions: ->
    hero = @world.getThangByID 'Hero Placeholder'
    for ogre in @built when ogre.health > 0
      if ogre.pos.y < 55
        ogre.move {x: ogre.pos.x, y: 58}
      else if ogre.pos.y > 78
        ogre.move {x: ogre.pos.x, y: 75}
      else
        ogre.attack hero

  checkDeadlyPursuitVictory: ->
    return if @victoryChecked
    return if @world.age < 20
    ogresSurviving = (t for t in @world.thangs when t.team is 'ogres' and t.health > 0).length
    coinsLeft = @world.getSystem('Inventory').collectables.length
    if (not coinsLeft and not ogresSurviving) or @world.age > 119
      @victoryChecked = true
      @setGoalState 'collect-coins', 'success' unless coinsLeft
      @setGoalState 'ogres-die', 'success' unless ogresSurviving
      @world.endWorld true, 1

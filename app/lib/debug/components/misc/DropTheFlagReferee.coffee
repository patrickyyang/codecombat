Component = require 'lib/world/component'

module.exports = class DropTheFlagReferee extends Component
  @className: 'DropTheFlagReferee'
  
  chooseAction: ->
    t = @world.age

    # Maybe build a coin
    @setUpDropTheFlag() unless @dropTheFlagSetUp
    if (@world.age + 6) / 2 > (@built.length / 2) and t < 32
      @spawnCoin()

    # Maybe build an ogre
    @lastSpawnTime ?= -2.5
    if t < 36 and t - @lastSpawnTime > 9
      @spawnOgre()

    @checkDropTheFlagVictory()

  setUpDropTheFlag: ->
    @index = 0
    @dropTheFlagSetUp = true
    @spawnLocationMap =
      bottom: {x: 94, y: 15}
      middle: {x: 94, y: 34}
      top: {x: 94, y: 53}
    @spawnLocations = _.values @spawnLocationMap

  spawnCoin: ->
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
    built.pos.x = 13 + @world.rand.randf() * 11
    built.pos.y = 17 + @world.rand.randf() * 33
    built.addTrackedProperties ['pos', 'Vector']
    built.keepTrackedProperty 'pos'
    
  spawnOgre: ->
    index = @world.rand.rand @spawnLocations.length
    while @lastIndex? and index is @lastIndex
      index = @world.rand.rand @spawnLocations.length
    @lastIndex = index
    pos = @spawnLocations[@index++ % @spawnLocations.length]
    @buildXY 'ogre-m', pos.x, pos.y
    thang = @performBuild()
    thang.attack @world.getThangByID 'Hero Placeholder'
    @lastSpawnTime = @world.age

  checkDropTheFlagVictory: ->
    return if @victoryChecked
    ogresSurviving = (t for t in @world.thangs when t.team is 'ogres' and t.health > 0).length
    coinsLeft = @world.getSystem('Inventory').collectables.length
    if (not coinsLeft and not ogresSurviving) or @world.age > 54
      @victoryChecked = true
      @setGoalState 'collect-coins', 'success' unless coinsLeft
      @setGoalState 'ogres-die', 'success' unless ogresSurviving
      @world.endWorld true, 1

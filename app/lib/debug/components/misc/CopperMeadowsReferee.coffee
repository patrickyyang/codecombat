Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

mazes = []
mazes.push """
############
#    #######
#    ##  ###
#    #   ###
# ####     #
#    ##  # #
#### ##### #
#    #     #
#      #   #
############
"""

mazes.push """
############
###     ## #
#   ###    #
#    ##    #
#  ##### ###
####   #  ##
###  # ##  #
#   ## #   #
#   ##     #
############
"""

mazes.push """
############
#    ##   ##
#    ##   ##
#### ##    #
####  #### #
#  ## #### #
#   #   #  #
#   ###    #
###        #
############
"""

mazes.push """
############
#   #    ###
#   # #    #
#     ##   #
######   ###
##     #####
#    #######
#   ##    ##
###       ##
############
"""

mazes.push """
############
#     #  ###
#   #      #
#   ###### #
## ###     #
#  ####  # #
# #   #### #
#   #    # #
#   #      #
############
"""

module.exports = class CopperMeadowsReferee extends Component
  @className: 'CopperMeadowsReferee'
  mapWidth: 120
  mapHeight: 102

  chooseAction: ->
    @setUpMeadows() unless @meadowsSetUp
    @checkMeadowsVictory()
    
  setUpMeadows: ->
    @meadowsSetUp = true
    coinSpawnChances = [
      [0, 'bronze']
      [75, 'silver']
      [95, 'gold']
    ]
    ogreGroups = [
      ['ogre-munchkin-m', 'ogre-munchkin-f', 'ogre-thrower']
      ['ogre-munchkin-m', 'ogre-munchkin-f', 'ogre-munchkin-f']
      ['ogre-munchkin-m', 'ogre-munchkin-f', 'ogre-munchkin-m', 'ogre-munchkin-f', 'ogre-thrower']
      ['ogre-munchkin-m', 'ogre-munchkin-f', 'ogre-shaman']
      ['ogre-thrower', 'ogre-munchkin-f']
    ]
    #seedBucket = @world.rand.seed % mazes.length
    #console.log 'Setting meadow seed from', @world.rand.seed, 'to', seedBucket
    #@world.rand.setSeed seedBucket
    maze = mazes[@world.rand.seed % mazes.length].split('\n')
    maze.reverse()
    trees = []
    coins = []
    ogres = []
    mazeScaleFactor = maze[0].length / @mapWidth
    treeSize = 10
    treeSpacing = 8
    coinSize = 4
    ogreSize = 8
    for x in [-treeSpacing / 2 .. @mapWidth + treeSpacing / 2] by treeSpacing
      for y in [-treeSpacing / 2 .. @mapHeight + treeSpacing / 2] by treeSpacing
        treePos = new Vector(x + (-0.5 + @world.rand.randf()) * (treeSize - treeSpacing) / 2, y + (-0.5 + @world.rand.randf()) * (treeSize - treeSpacing) / 2, 6)
        overlap = 0
        for mazeX in [x - treeSize / 2 ... x + treeSize / 2]
          for mazeY in [y - treeSize / 2 ... y + treeSize / 2]
            if maze[Math.floor(mazeY * mazeScaleFactor)]?[Math.floor(mazeX * mazeScaleFactor)] is ' '
              ++overlap
        if overlap < 60
          @build "tree-stand-#{@world.rand.rand2(1, 7)}"
          tree = @performBuild()
          tree.pos = treePos
          tree.addTrackedProperties ['pos', 'Vector']
          tree.keepTrackedProperty 'pos'
          trees.push tree
        else if overlap >= 100
          nCoins = @world.rand.rand2(1, 6)
          for i in [0 ... nCoins]
            coinPos = new Vector(x + (-0.5 + @world.rand.randf()) * coinSize, y + (-0.5 + @world.rand.randf()) * coinSize, 0.5)
            n = @world.rand.randf() * 100
            for [spawnChance, type] in coinSpawnChances
              if n >= spawnChance
                buildType = type
              else
                break
            @build buildType
            coin = @performBuild()
            coin.pos = coinPos
            coin.addTrackedProperties ['pos', 'Vector']
            coin.keepTrackedProperty 'pos'
            coins.push coin
          if @spawnOgres
            @ogreSpawnPoints ?= []
            if not _.any(@ogreSpawnPoints, (p) -> p.distance({x: x, y: y}) < 30)
              @ogreSpawnPoints.push new Vector(x, y)
              console.log 'spawning ogres at', x, y
              if buildTypes = ogreGroups.shift()
                for buildType in buildTypes
                  @build buildType
                  ogre = @performBuild()
                  ogre.pos = new Vector(x + (-0.5 + @world.rand.randf()) * ogreSize, y + (-0.5 + @world.rand.randf()) * ogreSize, 0.5)
                  ogre.hasMoved = true
                  ogres.push ogre
    @world.getSystem('AI').onObstaclesChanged()
        
  checkMeadowsVictory: ->
    return if @victoryChecked
    coinsLeft = @world.getSystem('Inventory').collectables.length
    ogresSurviving = (t for t in @world.thangs when t.team is 'ogres' and t.health > 0).length
    if (not coinsLeft and not ogresSurviving) or @world.age > (if @spawnOgres then 89.8 else 69)
      @victoryChecked = true
      @setGoalState 'collect-coins', 'success' unless coinsLeft
      @setGoalState 'ogres-die', 'success' unless ogresSurviving or not @spawnOgres
      @world.endWorld true, 1

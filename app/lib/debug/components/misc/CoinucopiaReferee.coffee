Component = require 'lib/world/component'

module.exports = class CoinucopiaReferee extends Component
  @className: 'CoinucopiaReferee'
  chooseAction: ->
    if (@world.age + 6) / 3 > (@built.length / 2)
      spawnChances = [
        [0, 'bronze']
        [65, 'silver']
        [85, 'gold']
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
      #console.log 'found', n, 'which is', buildType, 'from', r, 'and have built', @built.length
      if @built.length is 1
        built.pos.x = 66
        built.pos.y = 46
      else if @built.length is 2
        built.pos.x = 43
        built.pos.y = 53
      else
        built.pos.x = 21 + @world.rand.randf() * 50
        built.pos.y = 21 + @world.rand.randf() * 42
      built.addTrackedProperties ['pos', 'Vector']
      built.keepTrackedProperty 'pos'

    if @world.getSystem('Inventory').teamGold.humans.gold >= 20
      @setGoalState 'collect-gold', 'success'

    if false
      # This is buggy, so let's just see if we ever need to automatically add flags for them like this before trying to fix.
      if @built[0].exists and not @addedFirstFlag
        @addFlag 'green', @built[0].pos
        @addedFirstFlag = true
      else if not @built[0].exists and @built[1].exists and @addedFirstFlag and not @addedSecondFlag
        @addFlag 'green', @built[1].pos
        @addedSecondFlag = true

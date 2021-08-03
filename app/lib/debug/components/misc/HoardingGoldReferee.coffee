Component = require 'lib/world/component'

module.exports = class HoardingGoldReferee extends Component
  @className: 'HoardingGoldReferee'
  
  

  spawnCoins: ->
    coinsToSpawn = 30
    pacmanMouth = Math.PI / 3
    pacmanBody = 2 * Math.PI - pacmanMouth
    while @built.length < coinsToSpawn
      buildType = @pickBuildType @coinSpawn.spawnChances
      angle = pacmanMouth / 2 + pacmanBody * @built.length / coinsToSpawn
      targetPos =
        x: @rectangles.coins.x + @rectangles.coins.width / 2 * Math.cos angle
        y: @rectangles.coins.y + @rectangles.coins.height / 2 * Math.sin angle
      coin = @instabuild buildType, targetPos.x, targetPos.y

  checkVictory: ->
    gold = @hero.gold
    if gold >= 25
      @world.setGoalState 'collect-enough', 'success'
    if gold >= 30
      @world.setGoalState 'not-too-much', 'failure'

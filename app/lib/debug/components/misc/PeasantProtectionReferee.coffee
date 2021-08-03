Component = require 'lib/world/component'

module.exports = class PeasantProtectionReferee extends Component
  @className: 'PeasantProtectionReferee'
  chooseAction: ->
    @setUpPeasantProtection() unless @peasantProtectionSetUp
    t = @world.age
    @lastSpawnTime ?= -2.5
    if t < 39 and ((t - @lastSpawnTime > 1.8) or ((t - @lastSpawnTime > 1.1) and not @heroIsNearCheckpoint()))
      @spawnSomething()
    ogre.attack(@peasant) for ogre in @built when ogre.health > 0
    if t > 40
      @checkPeasantProtectionVictory()

  setUpPeasantProtection: ->
    @peasantProtectionSetUp = true
    @spawnLocationMap =
      left: {x: 6, y: 36}
      right: {x: 74, y: 36}
    @spawnLocations = _.values @spawnLocationMap
    if @world.rand.randf() < 0.5
      @spawnLocations.reverse()
    @checkpoint = {x: 40, y: 36}
    @peasant = @world.getThangByID 'Victor'

  spawnSomething: ->
    buildTypes = ['ogre-munchkin-m', 'ogre-munchkin-f']
    buildType = buildTypes[@world.rand.rand buildTypes.length]
    if @built.length in [0, 1, 2, 3]
      pos = @spawnLocations[Math.floor(@built.length / 2) % @spawnLocations.length]
    else if @built.length in [7, 8, 9]
      pos = @spawnLocations[0]
    else if @built.length in [10, 11]
      pos = @spawnLocations[1]
    else
      pos = @spawnLocations[@world.rand.rand @spawnLocations.length]
    #pos.y += @world.rand.randf() * 8 - 4
    @buildXY buildType, pos.x, pos.y
    thang = @performBuild()
    thang.attack @peasant
    thang.specificAttackTarget = @peasant
    @lastSpawnTime = @world.age

  heroIsNearCheckpoint: ->
    hero = @world.getThangByID('Hero Placeholder')
    hero.distance(@checkpoint) < 10
    
  checkPeasantProtectionVictory: ->
    return if @victoryChecked
    humansSurviving = not (t for t in @world.thangs when t.team is 'humans' and t.health <= 0).length
    ogresSurviving = not (t for t in @world.thangs when t.team is 'ogres' and t.health <= 0).length
    if not humansSurviving
      @setGoalState 'humans-survive', 'failure'
      @setGoalState 'ogres-die', 'failure' if ogresSurviving
      @world.endWorld true, 3
      @victoryChecked = true
    else if @world.age > 44
      @setGoalState 'humans-survive', 'success'
      @setGoalState 'ogres-die', 'success' unless ogresSurviving
      @world.endWorld true, 1
      @victoryChecked = true
        
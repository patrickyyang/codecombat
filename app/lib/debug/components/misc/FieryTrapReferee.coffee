Component = require 'lib/world/component'

module.exports = class FieryTrapReferee extends Component
  @className: 'FieryTrapReferee'
  chooseAction: ->
    @setUpFieryTrap() unless @fieryTrapSetUp
    t = @world.age
    @lastSpawnTime ?= -2.5
    if t < 39 and ((t - @lastSpawnTime > 3.5) or ((t - @lastSpawnTime > 3.0) and @heroIsNearCheckpoint()))
      @spawnSomething()
    @checkFieryTrapVictory()

  setUpFieryTrap: ->
    @fieryTrapSetUp = true
    @spawnLocationMap =
      left: {x: 0, y: 34}
      right: {x: 80, y: 34}
    @spawnLocations = _.values @spawnLocationMap
    if @world.rand.randf() < 0.5
      @spawnLocations.reverse()
    @checkpoint = {x: 40, y: 34}
    @leftPeasant = @world.getThangByID 'Brandy'
    @rightPeasant = @world.getThangByID 'Paps'

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
    @buildXY buildType, pos.x, pos.y
    thang = @performBuild()
    if thang.pos.x < 40
      thang.attack @leftPeasant
    else
      thang.attack @rightPeasant
    console.log 'Built', buildType, thang.id, 'at', thang.pos, 'at time', @world.age
    @lastSpawnTime = @world.age

  heroIsNearCheckpoint: ->
    hero = @world.getThangByID('Hero Placeholder')
    hero.distance(@checkpoint) < 6
    
  checkFieryTrapVictory: ->
    humansSurviving = not (t for t in @world.thangs when t.team is 'humans' and t.health <= 0).length
    ogresSurviving = not (t for t in @world.thangs when t.team is 'ogres' and t.health <= 0).length
    if not humansSurviving
      @setGoalState 'humans-survive', 'failure'
      @setGoalState 'ogres-die', 'failure' if ogresSurviving
      @world.endWorld true, 3
    else if @world.age > 44
      @setGoalState 'humans-survive', 'success'
      @setGoalState 'ogres-die', 'success' unless ogresSurviving
      @world.endWorld true, 1
    
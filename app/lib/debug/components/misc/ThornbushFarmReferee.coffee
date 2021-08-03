Component = require 'lib/world/component'

module.exports = class ThornbushFarmReferee extends Component
  @className: 'ThornbushFarmReferee'
  chooseAction: ->
    @setUpThornbush() unless @thornbushSetUp
    t = @world.age
    @lastSpawnTime ?= -2.5
    if t < 39 and ((t - @lastSpawnTime > 6) or ((t - @lastSpawnTime > 2.5) and @heroIsNearCheckpoint()))
      @spawnSomething()
    @checkThornbushVictory()

  setUpThornbush: ->
    @thornbushSetUp = true
    @spawnLocationMap =
      top: {x: 43, y: 70}
      left: {x: 3, y: 34}
      bottom: {x: 43, y: -1}
    @spawnLocations = _.values @spawnLocationMap
    @checkpointLocationMap =
      top: {x: 43, y: 50}
      left: {x: 25, y: 34}
      bottom: {x: 43, y: 20}
    @checkpointLocations = _.values @checkpointLocationMap
    # Set speed to prevent breaking the level with speed boosts
    hero = @world.getThangByID 'Hero Placeholder'
    hero.maxSpeed = 8

  spawnSomething: ->
    buildTypes = ['ogre-m', 'ogre-m', 'peasant-m', 'peasant-f']
    buildType = buildTypes[@world.rand.rand buildTypes.length]
    if @built.length in [0, 1, 2]
      buildType = 'ogre-m'
    else if @built.length is 3
      buildType = 'peasant-m'
    else if @built.length is 5
      buildType = 'peasant-f'
    pos = @spawnLocations[@built.length % @spawnLocations.length]
    @buildXY buildType, pos.x, pos.y
    thang = @performBuild()
    if /peasant/.test buildType
      thang.setTargetPos x: 47 + 6 * @world.rand.randf(), y: 30 + 5 * @world.rand.randf()
      thang.setAction 'move'
    else
      thang.attack thang.getNearestEnemy()
    console.log 'Built', buildType, thang.id, 'at', thang.pos, 'at time', @world.age
    @lastSpawnTime = @world.age

  heroIsNearCheckpoint: ->
    hero = @world.getThangByID('Hero Placeholder')
    checkpoint = @checkpointLocations[@built.length % @checkpointLocations.length]
    hero.distance(checkpoint) < 6
    
  checkThornbushVictory: ->
    humansSurviving = not (t for t in @world.thangs when t.team is 'humans' and t.health <= 0).length
    ogresSurviving = (t for t in @world.thangs when t.team is 'ogres' and t.health > 0).length
    if not humansSurviving
      @setGoalState 'humans-survive', 'failure'
      @setGoalState 'ogres-die', 'failure' if ogresSurviving
      @world.endWorld true, 3
    else if @world.age > 44
      @setGoalState 'humans-survive', 'success'
      @setGoalState 'ogres-die', 'success' unless ogresSurviving
      @world.endWorld true, 1

Component = require 'lib/world/component'

module.exports = class VillageGuardReferee extends Component
  @className: 'VillageGuardReferee'

  chooseAction: ->
    @setUpVillage() unless @villageSetUp
    t = @world.age
    @lastSpawnTime ?= -2.5
    heroSpeedFactor = @world.getThangByID('Hero Placeholder').maxSpeed / 6
    if t < 25 and ((t - @lastSpawnTime > (1 + 5 / heroSpeedFactor)) or ((t - @lastSpawnTime > 2) and @heroIsNearCheckpoint()))
      @spawnSomething()
    @checkVillageVictory()

  setUpVillage: ->
    @villageSetUp = true
    @spawnLocationMap =
      left: {x: 13, y: 34}
      right: {x: 82, y: 31}
    @spawnLocations = _.values @spawnLocationMap
    @checkpointLocationMap =
      left: {x: 35, y: 34}
      right: {x: 60, y: 31}
    @checkpointLocations = _.values @checkpointLocationMap
  
  spawnSomething: ->
    buildTypes = ['ogre-munchkin-f', 'ogre-munchkin-m', 'peasant-m', 'peasant-f']
    buildType = buildTypes[@world.rand.rand buildTypes.length]  # Not actually random at all if hero is slow, since we only build 6
    if @built.length in [0, 4]
      buildType = 'ogre-munchkin-f'
    else if @built.length in [1, 5]
      buildType = 'ogre-munchkin-m'
    else if @built.length is 2
      buildType = 'peasant-m'
    else if @built.length is 3
      buildType = 'peasant-f'
    pos = @spawnLocations[@built.length % @spawnLocations.length]
    @buildXY buildType, pos.x, pos.y
    thang = @performBuild()
    if /peasant/.test buildType
      thang.setTargetPos x: 35 + 9 * @world.rand.randf(), y: 38 + 8 * @world.rand.randf()
      thang.setAction 'move'
    else if enemy = thang.getNearestEnemy()
      thang.attack enemy
    console.log 'Built', buildType, thang.id, 'at', thang.pos, 'at time', @world.age
    @lastSpawnTime = @world.age

  heroIsNearCheckpoint: ->
    hero = @world.getThangByID('Hero Placeholder')
    checkpoint = @checkpointLocations[@built.length % @checkpointLocations.length]
    hero.distance(checkpoint) < 6
    
  checkVillageVictory: ->
    humansSurviving = not (t for t in @world.thangs when t.team is 'humans' and t.health <= 0).length
    ogresSurviving = (t for t in @world.thangs when t.team is 'ogres' and t.health > 0).length > 1  # There's a decoy ogre at the top that doesn't fight
    if not humansSurviving
      @setGoalState 'humans-survive', 'failure'
      @setGoalState 'ogres-die', 'failure' if ogresSurviving
      @world.endWorld true, 3
    else if @world.age > 29
      @setGoalState 'humans-survive', 'success'
      @setGoalState 'ogres-die', 'success' unless ogresSurviving
      @world.endWorld true, 1

Component = require 'lib/world/component'

module.exports = class BonemenderReferee extends Component
  @className: 'BonemenderReferee'
  chooseAction: ->
    @setUpBonemender() unless @bonemenderSetUp
    t = @world.age
    wave = @waves[0]
    if wave and t >= wave.time
      @spawnWave wave
      @waves.shift()
    @controlSoldier(@world.getThangByID(soldierID)) for soldierID in ['Bernard', 'Chandra']
    @checkBonemenderVictory()

  setUpBonemender: ->
    @bonemenderSetUp = true
    @spawnLocationMap =
      top: {x: 43, y: 58}
      left: {x: 3, y: 34}
      bottom: {x: 43, y: 12}
    @spawnLocations = _.values @spawnLocationMap
    @checkpointLocationMap =
      top: {x: 43, y: 48}
      left: {x: 43, y: 35}
      bottom: {x: 43, y: 22}
    @checkpointLocations = _.values @checkpointLocationMap
    # M is Munchkin, T is Thrower, O is Ogre
    @waves = [
      {time: 0, location: 'top', ogres: ['MT']},
      {time: 10, location: 'bottom', ogres: ['MMT']},
      {time: 20, location: 'left', ogres: ['MM']},
      {time: 30, location: 'top', ogres: ['TT', 'MMT']},
      {time: 40, location: 'bottom', ogres: ['MMMM', 'MMT']},
      {time: 50, location: 'top', ogres: ['O']} # based on sample code, Bernard is the preferred heal target; have the ogre spawn on his side so that he tanks.
    ]
    
  spawnWave: (wave) ->
    ogreKeys = wave.ogres[@world.rand.rand wave.ogres.length]
    buildTypeChoices = ({M: ['ogre-munchkin-f', 'ogre-munchkin-m'], T: ['ogre-thrower'], O: ['ogre-m']}[key] for key in ogreKeys)
    buildTypes = (choices[@world.rand.rand choices.length] for choices in buildTypeChoices)
    for buildType in buildTypes
      spawnPos = @spawnLocationMap[wave.location]
      checkpointPos = @checkpointLocationMap[wave.location]
      @buildXY buildType, spawnPos.x + 3 * (-0.5 + @world.rand.randf()), spawnPos.y + 1.5 * (-0.5 + @world.rand.randf())
      thang = @performBuild()
      thang.attack thang.getNearestEnemy()
      #console.log 'Built', buildType, thang.id, 'at', thang.pos, 'at time', @world.age
  
  controlSoldier: (soldier) ->
    hero = @world.getThangByID 'Hero Placeholder'
    checkpointPos = {Bernard: @checkpointLocationMap.top, Chandra: @checkpointLocationMap.bottom}[soldier.id]
    enemies = soldier.getEnemies()
    bigOgre = _.find @world.thangs, (thang) => thang.type is 'ogre' and thang.exists and not thang.dead

    if bigOgre
      # TODO: lure the big ogre in and then fight it together
      otherSoldier = @world.getThangByID {Bernard: 'Chandra', Chandra: 'Bernard'}[soldier.id]
      if soldier.distance(otherSoldier) > 4
        soldier.move otherSoldier.pos
        if soldier.distance(bigOgre) < otherSoldier.distance(bigOgre)
          soldier.say("Backup!")
        else if 28 < soldier.distance(bigOgre) < 30
          soldier.say("Hold on!")
      else
        if soldier.id is 'Chandra' and soldier.distance(bigOgre) > 5
          soldier.say("Stop him!")
        soldier.attack(bigOgre)

    else if enemies.length
      soldier.attack soldier.getNearestEnemy()

    else if soldier.hasEffect('regen') or soldier.health > 150
      if soldier.hasEffect('regen') and (not soldier.targetPos or soldier.targetPos.distance(checkpointPos) > 1)
        soldier.say("Thanks!")
      soldier.move checkpointPos

    else if soldier.distance(hero) > 10
      soldier.say("I need regeneration!")
      soldier.move hero.pos

    else
      soldier.say("I need regeneration!")
      soldier.setTargetPos null
      soldier.setAction 'idle'

  checkBonemenderVictory: ->
    humansSurviving = not (t for t in @world.thangs when t.team is 'humans' and t.health <= 0).length
    ogresSurviving = (t for t in @world.thangs when t.team is 'ogres' and t.health > 0).length
    if not humansSurviving
      @setGoalState 'humans-survive', 'failure'
      @setGoalState 'ogres-die', 'failure' if ogresSurviving
      @world.endWorld true, 3
    else if @world.age > 59
      @setGoalState 'humans-survive', 'success'
      @setGoalState 'ogres-die', 'success' unless ogresSurviving
      @world.endWorld true, 1

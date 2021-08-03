Component = require 'lib/world/component'

module.exports = class MedicalAttentionReferee extends Component
  @className: 'MedicalAttentionReferee'
  chooseAction: ->
    @setUp() unless @didSetUp
    wave = @waves[0]
    if wave and @world.age >= wave.time
      @spawnWave(wave)
      @waves.shift()
    @controlMinion(m) for m in @built when m.health > 0
    @controlSoldier(@world.getThangByID(id)) for id in @soldierIDs
    @controlHealer()
    @checkVictory()

  setUp: ->
    hero = @world.getThangByID "Hero Placeholder"
    @hero = hero
    hero.seesThroughWalls = true
    
    @didSetUp = true
    @soldierIDs = [ 'Joan', 'Augustus', 'Nikita' ]
    @healRequests = [ 'Heal me!', 'Heal, please!', 'I need healing!' ]
    @healMark = { x:65, y:46 }
    for soldierID in @soldierIDs
      soldier = @world.getThangByID(soldierID)
      soldier.atHealMark = false
      soldier.requestedHeal = false
    @buildTypeNames = {
      M: ['ogre-munchkin-f', 'ogre-munchkin-m']
      C: ['ogre-scout-f', 'ogre-scout-m']
      T: ['ogre-thrower']
      O: ['ogre-m']
      S: ['ogre-shaman']
      F: ['ogre-f']
    }
    @positions = {
      n:   { x:41, y:68 }
      n1:  { x:49, y:55 }
      e:   { x:80, y:33 }
      e1:  { x:65, y:34 }
      sw:  { x: 4, y: -4 }
      sw1: { x:30, y:24 }
      c: {x:51, y:41}
    }
    paths = {
      N:  [ @positions.n, @positions.n1 ]
      E:  [ @positions.e, @positions.e1 ]
      SW: [ @positions.sw, @positions.sw1 ]
    }
    @waves = [
      { time: 1, path:paths.SW, ogres:'C' }
      { time:12, path:paths.E,  ogres:'CC' }
      { time:17, path:paths.N,  ogres:'CCC' }
      { time:22, path:paths.SW, ogres:'OO' }
      { time:34, path:paths.E,  ogres:'O' }
      { time:44, path:paths.N,  ogres:'CCC' }
      { time:54, path:paths.SW,  ogres:'OO' }
    ]
    healer = @world.getThangByID 'Doctor Beak'
    @healer = healer
    healer.healQueue = []

  spawnWave: (wave) ->
    buildTypeChoices = (@buildTypeNames[key] for key in wave.ogres)
    buildTypes = (choices[@world.rand.rand choices.length] for choices in buildTypeChoices)
    for buildType in buildTypes
      spawnPos = wave.path[0]
      buildx = spawnPos.x + 2 * (-0.5 + @world.rand.randf())
      buildy = spawnPos.y + 2 * (-0.5 + @world.rand.randf())
      @buildXY buildType, buildx, buildy
      minion = @performBuild()
      minion.origSpeed = minion.maxSpeed
      minion.wave = wave
      minion.path = wave.path.slice()

  controlMinion: (minion) ->
    hero = @world.getThangByID 'Hero Placeholder'
    path = minion.path
    if path.length > 0
      waypoint = path[0]
      if waypoint
        minion.move waypoint
        if minion.distance(waypoint) < 4
          path.shift()
    else
      #enemy = if (minion.type == 'shaman') then hero else minion.getNearestEnemy()
      if minion.distanceTo(hero) <= minion.attackRange
        enemy = hero
      else
        enemy = minion.getNearestEnemy()
      if enemy
        minion.attack(enemy)
        if enemy.target is minion
          minion.maxSpeed = minion.origSpeed * 0.95
        else
          minion.maxSpeed = minion.origSpeed;
      else # move to the middle of the screen
        minion.move(@positions.c)

  controlSoldier: (soldier) ->
    return if soldier.health <= 0
    if soldier.health < (soldier.maxHealth * 0.6)
      if soldier.distanceTo(@healMark) < 3
        if not soldier.requestedHeal or soldier.requestedHeal < @world.age - 1.5
          soldier.requestedHeal = @world.age
          soldier.say(@healRequests[@world.rand.rand @healRequests.length])
      else
        if not soldier.atHealMark
          if soldier.distanceTo(@healMark) < 3
            soldier.atHealMark = true
          else
            soldier.move(@healMark)
    else
      if soldier.requestedHeal
        soldier.requestedHeal = false
        if soldier.distanceTo(@healMark) > 3
          soldier.atHealMark = false
      enemy = soldier.findNearestEnemy()
      soldier.attack(enemy)

  # Make sure that all heal requests get fulfilled.
  controlHealer: ->
    healer = @world.getThangByID 'Doctor Beak'
    if healer.canCast('heal') and healer.healQueue.length > 0
      target = healer.healQueue[0]
      if target
        if target.health < target.maxHealth
          healer.cast('heal', target)
          healer.say('Healed!')
        healer.healQueue.shift()
    else if healer.healQueue.length is 0
      healer.setAction 'idle'

  checkVictory: ->
    return if @victoryChecked
    if not @waves.length and not (t for t in @built when t.health > 0).length
      @world.setGoalState 'ogres-die', 'success'
      @victoryChecked = true
      
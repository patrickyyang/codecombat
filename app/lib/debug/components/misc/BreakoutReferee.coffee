Component = require 'lib/world/component'

module.exports = class BreakoutReferee extends Component
  @className: 'BreakoutReferee'

  #Balance variables
  munchkinsSpawnAfter = 3.3
  munchkinSpawnCooldown = 1.4
  
  chooseAction: ->
    @setUp() unless @didSetUp
    @controlSoldier()
    @spawnMunchkin()
    @checkFinalDoor()
    
  setUp: ->
    @didSetUp = true
    @door = @world.getThangByID 'Weak Door'
    @door2 = @world.getThangByID 'Door'
    @doorSpikes = @world.getThangByID 'Spike Walls'
    @spawnTime = 0
    @buildTypes = ['ogre-munchkin-f', 'ogre-munchkin-m']
    @endPhase = false
    @impaled = false
    @hurryUp = true
    @halfway = false
    
    @hero.oAttack = @hero.attack
    @hero.attack = (target) ->
      attackTarget = @world.getThangByID target
      if attackTarget? and @action is "say"
        unless @attackCount
          @attackCount = 2
        else
          @attackCount++
        if @attackCount >= 2
          @world.setGoalState "weak-door-assault", "failure"
          console.log(JSON.stringify(@world.goalManager.goalStates["weak-door-assault"]))
      @oAttack target
    
    #missile = @world.getThangByID 'Fireball'
    #console.log 'MISSILE', missile.id
    #missile.explode = -> true

  controlSoldier: ->
    soldier = @world.getThangByID 'Heather'
    soldier.say "Hello? Is someone there?" unless @door.dead
    if @door.dead and !soldier.hasSaid?
      soldier.say "Thank you! Let's get out of here!" 
      soldier.hasSaid = true
    return unless @door.dead
    #@setGoalState 'ally', 'success'
    enemy = soldier.getNearestEnemy()
    # Move to the end of the hall
    if soldier.pos.x < 37
      soldier.setTargetPos x: 38, y: 46
      soldier.setAction 'move'

    else if @endPhase and soldier.pos.y > 40.5
      soldier.setTarget soldier.getNearestFriend()
      soldier.setAction 'move'

    # Defend the player
    else if enemy
      if @hurryUp
        soldier.say "I'll cover you while you break down that door!"
        @hurryUp = false
      if not @halfway and @door2.health <= @door2.maxHealth / 2
          soldier.say "The door is almost broken!"
          @halfway = true
      soldier.setTarget enemy
      soldier.setAction 'attack'

  spawnMunchkin: ->
    return unless @world.age > munchkinsSpawnAfter
    return unless @world.age > @spawnTime + munchkinSpawnCooldown
    return if  @endPhase and @world.age > @endPhase + 2
    munchkins = (m for m in @world.thangs when m.type is 'munchkin' and not m.dead)
    return if munchkins.length > 5
    buildType = @buildTypes[@world.rand.rand @buildTypes.length]
    spawnPos = @points.ogreSpawn
    @buildXY buildType, spawnPos.x, spawnPos.y
    @performBuild()
    @spawnTime = @world.age

  controlOgres: (ogres) ->
    for ogre in ogres
      target = ogre.getNearestEnemy()
      if target and target.id isnt 'Weak Door'
        ogre.setTarget target
        ogre.attack target
      else
        ogre.setTargetPos x: 38, y: 46
        ogre.setAction 'move'
  
  update: ->
    if @door? and @door.dead
      if @doorSpikes?
        @doorSpikes.setExists false
    door2 = @world.getThangByID 'Door'
    if door2.health <= 0 and @hero.snapPoints
      #thang.snapPoints = movementSystem.simpleMoveSnapPoints
      @hero.snapPoints.pop()

  checkFinalDoor: ->
    door = @world.getThangByID 'Door'
    return if door.health > 0
    @endPhase = @world.age unless @endPhase
    @triggerGargoyle()
    ogres = (ogre for ogre in @world.thangs when ogre.type is 'munchkin' and not ogre.dead)
    @setGoalState 'escape', 'success' unless ogres.length > 0
    
  triggerGargoyle: ->
    soldier = @world.getThangByID 'Heather'
    return unless soldier.pos.y < 41
    #return if @impaled
    gargoyle = @world.getThangByID 'Gargoyle'
    gargoyle.impale x: 10, y: 45
    #for t in @world.thangs when t.type is 'munchkin' and t.pos.y > 44
      #gargoyle.impale t
    
    @impaled = true    
    
Component = require 'lib/world/component'

module.exports = class HackAndDashReferee extends Component
  @className: 'HackAndDashReferee'

  chooseAction: ->
    @setUp() unless @didSetUp
    @controlBoulder()
    @checkPotion() unless @potionState is 'drank'
    @yeti.patrol @patrolPoints

  setUp: ->
    @didSetUp = true
    @boulder = @world.getThangByID 'Dungeon Sprite'
    @boulder.maintainsElevation = -> true
    
    @boulderTargets = [
      { x: 86, y: 112 }
      { x: 86, y: 74 }
      { x: 122, y: 74 }
      { x: 122, y: 38 }
      { x: 158, y: 38 }
      { x: 158, y: 14 }
    ]

    @hero = @world.getThangByID 'Hero Placeholder'
    
    @boulder.maxSpeed = @hero.maxSpeed + 5
    
    @chest = @world.getThangByID 'Chest'
    
    @potionState = 'chest'
    @potion = @world.getThangByID 'Speed Potion'
    
    @yeti = @world.getThangByID 'Fluffy'
    @yeti.hidden = true
    @patrolPoints = [
      { x: 18.5, y: 24 }
      { x: 26, y: 24 }
    ]

  boulderActive: ->
    return true if @hero.pos.x > 54
    return false
    
  controlBoulder: ->
    @boulder.setExists true
    return if not @boulderActive()
    if not @boulder.targetPos or @boulderShouldChangeTarget()
      if @boulderTargets.length
        @boulder.setTargetPos @boulderTargets[0]
        @boulderTargets.shift()

    @boulder.velocity.x = @boulder.targetPos.x - @boulder.pos.x
    @boulder.velocity.y = @boulder.targetPos.y - @boulder.pos.y
    @boulder.velocity.z = 0
    @boulder.velocity.normalize().multiply @boulder.maxSpeed
    @boulderHitHero() if @hero.distanceTo(@boulder) < 2

  boulderShouldChangeTarget: ->
    return true if Math.abs(@boulder.velocity.x) > 2 and @boulder.pos.x >= @boulder.targetPos.x
    return true if Math.abs(@boulder.velocity.y) > 2 and @boulder.pos.y <= @boulder.targetPos.y
    return false
    
  boulderHitHero: ->
    @hero.takeDamage 9000 unless @hero.dead

  checkPotion: ->
    if @potionState is 'chest' and @chest.dead
      @spawnPotion()
    if @potionState is 'spawned' and not @potion.exists
      @drinkPotion()

  spawnPotion: ->
    @potion.setExists true
    @potionState = 'spawned'
    
  drinkPotion: ->
    @hero.maxSpeed += 4
    @potionState = 'drank'
    console.log 'POTION drank'    
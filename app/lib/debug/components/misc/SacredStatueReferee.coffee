Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class SacredStatueReferee extends Component
  @className: 'SacredStatueReferee'
  chooseAction: ->
    @checkVictory()
    @configure()
    @decrementTimers()
    @companionRoutine()
    @statueRadiance()
    
    # statue will not trigger event until you clear all the static ogres
    if @ellipses['statue-radius'].containsPoint(@hero.pos) and not @enemiesCleared() and not @events.statueTriggered
      @statue.say? "There is a foul presence nearby, please eliminate the threat"
    
    else if not @ellipses['statue-radius'].containsPoint(@hero.pos) and @enemiesCleared() and not @events.dialog1
      @statue.say? "Come closer, hero!"
    
    # statue dialog begins
    else if @ellipses['statue-radius'].containsPoint(@hero.pos) and not @events.dialog1
      @statue.say? "You are just in time great champion, the ogres are preparing an attack!"
      @events.dialog1 = @world.age
      @events.statueTriggered = true
      
    # statue dialog continues
    else if @events.dialog1 and (@world.age - @events.dialog1) >= 4 and not @events.dialog2
      @statue.say? "You cannot not let them desecrate this holy ground."
      @events.dialog2 = @world.age
    
    # statue actually activates now and begins emmiting holy radiance
    else if @events.dialog2 and (@world.age - @events.dialog2) >= 4 and not @events.dialog3
      @statue.say? "Stay close to me during the battle so I can assist you!"
      @events.dialog3 = @world.age
      @statueActive = true
    
    # dialog is finished trigger starting of waves  
    else if @events.dialog3 and (@world.age - @events.dialog3) >= 4 and not @events.spawnsBegin
      @events.spawnsBegin = true
      @currentWave = 1
    
    # all waves are done, spawn the boss
    else if @currentWave > @numberOfWaves and @timers.waveTimer <= 0 and @enemiesCleared() and not @events.bossSpawn
      @spawnBoss()
      @events.bossSpawn = true
      
    # generate waves
    else if @events.spawnsBegin and not @events.bossSpawn
      @generateWaves()
  
  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    @statue = @world.getThangByID 'Sacred Statue'
    @cyclops = @world.getThangByID 'Ancient Cyclops'
    
    @events =
      'statueTriggered': false
      'dialog1': false
      'dialog2': false
      'dialog3': false
      'spawnsBegin': false
      'bossSpawn': false
    
    @spawnLocations = [
      'top-left'
      'top-right'
      'bottom-left'
      'bottom-right'
    ]
    
    @aura =
      "currentColor": false
      "normalColor": 'rgba(255, 255, 128, 0.24)'
      "blastColor": 'rgba(255, 0, 0, 0.18)'
    
    @timers =
      "statueTimer": 0
      "waveTimer": 0
      "waveCooldown": 0
      "buildUpTimer": 0
    
    @statueActive = false
    @numberOfWaves = 3
    @waveDuration = 10
    @waveTimeout = 0
    @nextWaveQueued = false
    
    @removeStaticUnits =
      "shaman": false
      "throwers": false
      "scouts": false
  
  configure: ->
    return unless not @configured
    
    if @hero.type in ['captain', 'knight', 'samurai', 'ninja', 'trapper']
      @companion = @instabuild("healer-hero", -2, 14)
    else
      @companion = @instabuild("melee-hero", -2, 14)
      
    @aura.currentColor = @aura.normalColor
    @healRate = ((2.4 / 100) * @hero.maxHealth)
    @healRate = if @healRate > 40 then 40 else @healRate
    
    #@nerfStatics()
    @configured = true
  
  configureCyclops: ->
    @cyclops.maxHealth = (@hero.maxHealth / 5) * 4
    @cyclops.health = @cyclops.maxHealth
    @cyclops.addTrackedProperties ['health', 'number']
    @cyclops.keepTrackedProperty 'health'
    
    @cyclops.attackDamage = @hero.maxHealth / ((9 / 100) * @hero.maxHealth) + ((3.5 / 100) * @hero.maxHealth)
    @cyclops.attackDamage = if @cyclops.attackDamage > 70 then 70 else @cyclops.attackDamage
    @cyclops.attackDamage += @world.difficulty * 6
    
    @cyclops.addTrackedProperties ['attackDamage', 'number']
    @cyclops.keepTrackedProperty 'attackDamage'
  
  decrementTimers: ->
    for name, timer of @timers
      @timers[name] -= @world.dt
  
  createRectangle: (name, rect) ->
    #
    # createRectangle
    #   | This creates a rectangle that can be used with spawn waves or triggers
    #
    @rectangles[name] = rect
  
  assignWaveRegion: (wave, region, rect) ->
    #
    # assignWaveRegion
    #   | creates a spawn rectangle and then assigns it to the specified wave
    #
    @createRectangle region, rect
    _.find(@waves, name: wave).regions = [region]
  
  companionRoutine: ->
    #
    # companionRoutine
    #   | handles the companion behavior, healing, attacking, etc
    #
    @companionMovement()
    enemy = @companion.findNearestEnemy()
    if enemy
      distance = @companion.distanceTo(enemy)
    if @companion.type is "healer"
      if @hero.health < @hero.maxHealth and @companion.canCast("regen", @hero)
        @companion.cast("regen", @hero)
      else if @companion.health < @companion.maxHealth and @companion.canCast("regen", @companion)
        @companion.cast("regen", @companion)
      if enemy and distance
        if distance <= 35
          @companion.attack(enemy)
    else
      if enemy and distance
        if distance <=5
          if @companion.isReady("bash")
            @companion.bash(enemy)
          if @companion.isReady("cleave")
            @companion.cleave(enemy)
          @companion.attack(enemy)
  
  companionMovement: ->
    #
    # companionMovement
    #   | handles the companion movement
    #
    if not @companion.dead and not @hero.dead
      @companion.move(Vector.subtract(@companion.pos, @hero.pos).normalize().multiply(3).add(@hero.pos))
  
  nerfStatics: ->
    #
    # nerfStatics
    #   | nerf some static spawns to make the level easier when needed
    #
    #if @hero.maxHealth <= 700
    @removeStaticUnits.shaman = true
    @removeStaticUnits.throwers = true
    @removeStaticUnits.scouts = 1
    #else if @hero.maxHealth <= 1000
    #  @removeStaticUnits.shaman = true
    #  @removeStaticUnits.throwers = true
    #else if @hero.maxHealth <= 1500
    #  @removeStaticUnits.shaman = true
      
    if @removeStaticUnits.shaman
      shamans = (t for t in @world.getSystem("Combat").attackables when t.isAttackable and t.type is "shaman" and t isnt @hero)
      for shaman in shamans
        shaman.isAttackable = false
        shaman.setExists(false)
    
    if @removeStaticUnits.throwers
      throwers = (t for t in @world.getSystem("Combat").attackables when t.isAttackable and t.type is "thrower" and t isnt @hero)
      for thrower in throwers
        thrower.isAttackable = false
        thrower.setExists(false)
        
    if @removeStaticUnits.scouts
      count = 0
      scouts = (t for t in @world.getSystem("Combat").attackables when t.isAttackable and t.type is "scout" and t isnt @hero)
      for scout in scouts
        if @removeStaticUnits.scouts and count < @removeStaticUnits.scouts
          scout.isAttackable = false
          scout.setExists(false)
          count++
  
  spawnBoss: ->
    #
    # spawnBoss
    #   | spawns the boss
    #
    @cyclops.appearanceDelay = 0
    r = Math.round(@world.rand.randf2(0, 3))
    spawnPoint = @pickPointFromRegions([@ellipses[@spawnLocations[r]]])
    
    @configureCyclops()
    
    @cyclops.say? "GRRRAAWWR!"
    @cyclops.attack @hero
  
  generateWaves: ->
    #
    # generateWaves
    #   | handles the wave spawning logic
    #
    if not @nextWaveQueued
      if @timers.waveTimer <= 0 and @timers.waveCooldown <= 0 and @enemiesCleared()
        @nextWaveQueued = true
        @timers.waveCooldown = 5
      else 
        @timers.waveTimer = 1
    
    # if cooldown is up or it's been 20 seconds since the wave was first spawned, spawn the next wave
    return unless ((@timers.waveTimer <= 0 and @timers.waveCooldown <= 0) or @world.age - @waveTimeout >= 20) and @currentWave <= @numberOfWaves
    
    # choose 2 spawn locations randomly | top left | top right | bottom left | bottom right
    r = Math.round(@world.rand.randf2(0, 3))
    r2 = Math.round(@world.rand.randf2(0, 3))
    while r2 is r
      r2 = Math.round(@world.rand.randf2(0, 3))
    
    @spawnWaveNamed @spawnLocations[r] + "-initial"
    @spawnWaveNamed @spawnLocations[r2] + "-initial"
    @spawnWaveNamed @spawnLocations[r] + "-duration"
    @spawnWaveNamed @spawnLocations[r2] + "-duration"
    
    @sendEnemies()
    
    @waveTimeout = @world.age
    @timers.waveTimer = @waveDuration
    @currentWave++
  
  emitAura: ->
    #
    # emitAura
    #   | emits the aura around the statue
    #
    if @statueActive and @world.frames.length % 4 is 0 and @world.rand.randf() < 0.75
      args = [61.5, 71, 17, @aura.currentColor, 0, 0, "floating"]
      @addCurrentEvent? "aoe-#{JSON.stringify(args)}"
  
  thangAura: (thangs, color) ->
    #
    # thangAura
    #   | emits the aura around the units that are standing in the statue's radius
    #
    if @statueActive and @world.frames.length % 2 is 0 and @world.rand.randf() < 0.75
      for thang in thangs
        args = [thang.pos.x.toFixed(2), thang.pos.y.toFixed(2), (4 * thang.scaleFactor), color, 0, 0, "floating"]
        thang.addCurrentEvent? "aoe-#{JSON.stringify(args)}"
  
  statueRadiance: ->
    #
    # statueRadiance
    #   | handles the effects of the statue's aura.
    #
    @emitAura()
    
    enemies = (t for t in @world.getSystem("Combat").attackables when t.isAttackable and t.team is "ogres" and t isnt @hero and @ellipses['statue-radius'].containsPoint(t.pos))
    friends = (t for t in @world.thangs when t.team is 'humans' and t.exists and t.health >= 0 and @ellipses['statue-radius'].containsPoint(t.pos))
    
    @thangAura(enemies, @aura.blastColor)
    @thangAura(friends, @aura.normalColor)
    
    return unless @statueActive and @timers.statueTimer <= 0
    
    @aura.currentColor = @aura.normalColor
    
    # energy build up if there is more than 5 enemies and timer is up
    if enemies.length > 3 && @timers.buildUpTimer <= 0
      @say? "** Energy blast released! **"
      @aura.currentColor = @aura.blastColor
      for friend in friends
        if friend.health < friend.maxHealth
          friend.health += @healRate * 25
      
      for enemy in enemies
        enemy.health -= @healRate * 5
        enemy.addTrackedProperties ['health', 'number']
        enemy.keepTrackedProperty 'health'
      
      @timers.buildUpTimer = 12
    
    # heal friends and hero
    for friend in friends
      if friend.health < friend.maxHealth
        if @enemiesCleared()
          friend.health += @healRate * 2
        else
          friend.health += @healRate
    
    # damages ogres
    for enemy in enemies
      enemy.health -= @healRate / 16
      enemy.addTrackedProperties ['health', 'number']
      enemy.keepTrackedProperty 'health'
    
    # vortex effect. the idea is to pull enemies closer to the statue the closer to the statue the more momentum they get
    enemies = (t for t in @world.getSystem("Combat").attackables when t.isAttackable and t.team is "ogres" and t isnt @hero)
    for enemy in enemies
      if @statue.distanceTo(enemy) > 10
        @vortex(enemy)
    
    @timers.statueTimer = 0.35
  
  vortex: (enemy) ->
    #
    # vortex
    #   | handles the vortex effect of the statue's aura
    #
    ratio = 1 - @statue.pos.distance(enemy.pos) / 35
    momentum = @statue.pos.copy().subtract(enemy.pos, true).multiply(ratio * (75 - (@statue.distanceTo(enemy) * 1.2)), true)
    enemy.velocity.add momentum.divide(enemy.mass, true), true
    enemy.rotation = (enemy.velocity.heading() + Math.PI) % (2 * Math.PI)
  
  sendEnemies: ->
    #
    # sendEnemies
    #   | sends all enemies to attack the hero when they spawn
    #
    enemies = (t for t in @world.getSystem("Combat").attackables when t.isAttackable and t.team is "ogres" and not t.dead and t isnt @hero)
    for enemy in enemies
      enemy.attack @hero
  
  enemiesCleared: ->
    #
    # enemiesCleared
    #   | returns true if all enemies are cleared
    #
    enemies = (t for t in @world.getSystem("Combat").attackables when t.isAttackable and t.team is "ogres" and not t.dead and t isnt @hero)
    return enemies.length < 1
  
  checkVictory: ->
    if @hero.health <= 0
      @setGoalState 'protect', 'failure'
      @setGoalState 'survive', 'failure'
      @setGoalState 'cyclops', 'failure'
    else if @events.bossSpawn and @cyclops.health <= 0 and @enemiesCleared() and @hero.health > 0
      @setGoalState 'protect', 'success'
      @setGoalState 'survive', 'success'
      @setGoalState 'cyclops', 'success'
      
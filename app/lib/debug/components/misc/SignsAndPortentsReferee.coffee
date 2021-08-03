Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class SignsAndPortentsReferee extends Component
  @className: 'SignsAndPortentsReferee'

  chooseAction: ->
    @setUp() unless @didSetUp
    @checkCollections()

    @checkAllyActivation()    
    @controlAlly(ally) for ally in ['ninja', 'librarian', 'trapper', 'alchemist']

    @controlSkeletons()

    @checkWaveActivation()
    for name,time of @waveTimers
      wave = @waves[name][0]

      if wave and @world.age >= (wave.time + time)
        @spawnWave(wave)
        @waves[name].shift()

  setUp: ->
    @didSetUp = true
    @hero = @world.getThangByID 'Hero Placeholder'
    @hero.gemsCollected = 0

    @ninja = @world.getThangByID 'Amara'
    @hush = @world.getThangByID 'Hushbaum'
    @trapper = @world.getThangByID 'Senick'
    @alchemist = @world.getThangByID 'Omarn'
    
    # These triggers are in the form X: name
    # Where X is the x position the player must pass in order to trigger the named ally or waves of enemies
    @waveTriggers =
      3: 'ninja'
      40: 'librarian'
      64: 'trapper'

    @allyTriggers =
      10: 'ninja'
      36: 'librarian'
      64: 'trapper'
      68: 'alchemist'

    @buildTypeNames = 
      M: ['ogre-munchkin-f', 'ogre-munchkin-m']
      C: ['ogre-scout-f', 'ogre-scout-m']
      T: ['ogre-thrower']
      O: ['ogre-m']
      S: ['ogre-shaman']
      F: ['ogre-f']
      K: ['skeleton']

    # Once a wave is activated by the trigger point above, they will spawn at <time> seconds after activation.
    @waves = 
      ninja: [
        { time: 1, regions: ['ninjaSpawn'], ogres: 'MMMMMMM' }
        { time: 3, regions: ['ninjaSpawn'], ogres: 'CC' }
        { time: 5, regions: ['ninjaSpawn'], ogres: 'O' }
        { time: 8, regions: ['ninjaSpawn'], ogres: 'CC' }                
      ]
      librarian: [
        { time: 1, regions: ['librarianSpawn'], ogres: 'CCOMM' }
        { time: 3, regions: ['librarianSpawn'], ogres: 'SS' }
        { time: 6, regions: ['librarianSpawn'], ogres: 'MMMTT' }
      ]
      trapper: [
        { time: 3, regions: ['trapperSpawn'], ogres: 'KKKK' }
        { time: 6, regions: ['trapperOgreSpawn'], ogres: 'FFF' }
        { time: 8, regions: ['alchemistSpawn'], ogres: 'MMM' }
      ]

    # Once an ally is activated by the trigger above, they will switch state at <time> seconds after activation
    @allies = 
      ninja: [
        { time: 0.5, state: 'ninjaEntry' }
        { time: 1, state: 'ninjaGreeting' }
        { time: 2, state: 'ninjaFight' }
      ]
      librarian: [
        { time: 0.5, state: 'librarianGreeting' }
        { time: 2, state: 'librarianFight' }
      ]
      trapper: [
        { time: 0.1, state: 'trapperGreeting' }
        { time: 1, state: 'trapperCharge' }
        { time: 5, state: 'trapperBuild' }
        { time: 0.5, state: 'trapperFight' }
      ]
      alchemist: [
        { time: 0, state: 'alchemistCharge' }
        { time: 1.5, state: 'alchemistGreeting' }
        { time: 2.5, state: 'alchemistFight' }
      ]

    @waveTimers = {}

    @allyStates = 
      ninja: 'allyStart'
      librarian: 'allyStart'
      
    @allyTimers = {}
      
  ##### Enemies #####

  # Who's attackers are we spawning currently? For now, just based on the hero's pos.x
  checkWaveActivation: ->
    for x,name of @waveTriggers
      if @hero.pos.x > x and not @waveTimers[name]
        @waveTimers[name] = @world.age
        console.log 'activateNewWave', @hero.pos.x, name, 'at time', @world.age

  spawnWave: (wave) ->
    buildTypeChoices = (@buildTypeNames[key] for key in wave.ogres)
    buildTypes = (choices[@world.rand.rand choices.length] for choices in buildTypeChoices)
    for buildType in buildTypes
      regions = (@rectangles[region] for region in wave.regions)
      spawnPos = @pickPointFromRegions regions
      @buildXY buildType, spawnPos.x, spawnPos.y
      minion = @performBuild()

   # Did the hero collect a gem? Need a beter way to figure this out
  checkCollections: ->
    if @hero.gemsCollected < @hero.collectedThangIDs.length
      @hero.gemsCollected = @hero.collectedThangIDs.length
      @gemWasCollected _.last(@hero.collectedThangIDs)
      
  # Stuff to do when a gem is collected
  gemWasCollected: (gemID) ->
    gem = @world.getThangByID gemID
    gem.wasCollectedBy? @hero

  controlSkeletons: ->
    for skeleton in @world.thangs when skeleton.spriteName is "Skeleton" and skeleton.team isnt 'humans' and not skeleton.dead
      skeleton.chooseAction = ->
      enemies = skeleton.findEnemies()
      enemies = (e for e in enemies when e.distance(@hero) > 14) if @hero.hasActiveLightstone
      nearest = null
      if @hero.hasActiveLightstone and skeleton.distance(@hero) < 14 and (not skeleton.target or skeleton.target.distance(@hero) < 14)
        moveVector = skeleton.pos.copy().subtract(@hero.pos).normalize().multiply(5)
        if moveVector.y < 0
          # Don't let them get caught in a corner on the bottom; move them toward the ogres
          moveVector = new Vector(2, 5)
        skeleton.move skeleton.pos.copy().add moveVector
      else
        nearest = skeleton.findNearest(enemies)
        if nearest
          skeleton.attack(nearest)
        else unless @hero.dead
          skeleton.attack @hero

  ##### Allies #####
  
  checkAllyActivation: ->
    for x,name of @allyTriggers
      if @hero.pos.x > x and not @allyTimers[name]
        @allyTimers[name] = @world.age
        #console.log 'activateNewAlly', @hero.pos.x, name

  allyStart: ->
    return

  controlAlly: (ally) ->
    action = @allies[ally][0]
    if action and @world.age > (@allyTimers[ally] + action.time)
      @allyStates[ally] = action.state
      #console.log  ally, 'activated state', action.state
      @allies[ally].shift()
      
    @[@allyStates[ally]]?()

  ninjaEntry: ->
    @ninja.setTargetPos x: 15, y: 30
    @ninja.setAction 'move'
    @ninja.act()

  ninjaGreeting: ->
    @ninja.say 'I\'ll cover you, go!'

  
  ninjaFight: ->
    ninja = @world.getThangByID 'Amara'
    enemies = ninja.findEnemies()
    nearest = ninja.findNearest(enemies)
    max = @findMaxHP(enemies)
    if nearest
      distance = ninja.distanceTo(nearest)
      if enemies.length > 1 and distance < ninja.throwRange and distance > 9
        ninja.say 'self.THROW(enemy)'
        ninja.throw(nearest)
      else
        ninja.attack(nearest)
  
  librarianGreeting: ->
    @hush.say('Quickly, now! Keep moving!')
  
  librarianFight: ->
    hush = @world.getThangByID 'Hushbaum'
    enemies = hush.findEnemies()
    nearest = hush.findNearest(enemies)
    if nearest
      dist = hush.distanceTo(nearest)

      if dist < hush.spells.shockwave.range and hush.canCast('shockwave')
        hush.say('self.cast("SHOCKWAVE", enemy)')
        hush.cast('shockwave',nearest)
      else if hush.canCast('magic-missile') and dist < hush.spells['magic-missile'].range
        hush.say('self.cast("MAGIC-MISSILE", enemy)')
        hush.cast('magic-missile',nearest)
      else if hush.distanceTo(nearest) < hush.attackRange
        hush.attack(nearest)
  
  
  trapperGreeting: ->
    @trapper.say 'Grab that lightstone and follow me!'
    @trapper.setTargetPos x: 95, y: 18
    @trapper.setAction 'move'
    @trapper.act()
    
  trapperCharge: ->
    @trapper.setTargetPos x: 96, y: if @trapper.pos.x < 94 then 18 else 23
    @trapper.setAction 'move'
    @trapper.act()
    
  trapperBuild: ->
    unless @hasBuiltTrapperWall
      @hasBuiltTrapperWall = true
      @instabuild "fence", 94, 18

  trapperFight: ->
    enemies = @trapper.findEnemies()
    nearest = @trapper.findNearest(enemies)
    if nearest and nearest.team is 'neutral' and nearest.target?.team is 'ogres'
      # Shoot at ogres if skeletons are attacking ogres because of lightstone
      nearest = @trapper.findNearest (e for e in enemies when e.team is 'ogres') or nearest
    if nearest
      if @hero.distance(x: 90, y: 18) < 5 and @trapper.health < 60
        @trapper.health = 60
        @trapper.attackDamage = 60
      @trapper.attack(nearest)
  
  alchemistCharge: ->
    @alchemist.setTargetPos x: 93, y: 23.44
    @alchemist.setAction 'move'
    @alchemist.act()
    
  alchemistGreeting: ->
    @alchemist.say 'Stand near me with the lightstone.'

  alchemistFight: ->
    enemies = @alchemist.findEnemies()
    nearest = @alchemist.findNearest(enemies)
    if not @trapper.dead and @trapper.health < @trapper.maxHealth and @alchemist.canCast 'regen'
      @alchemist.say('self.cast("REGEN", "Senick")')
      @alchemist.cast('regen',@trapper)
    else if nearest
      if @hero.distance(x: 90, y: 18) < 5 and @alchemist.health < 60
        @alchemist.health = 60
        @alchemist.attackDamage = 60
      dist = @alchemist.distanceTo(nearest)
      @alchemist.attack(nearest)

  findMaxHP: (thangs) ->
    return null unless thangs
    max = 0
    enemy = null
    for t in thangs
      if t.health > max
        max = t.health
        enemy = t
    return enemy
    
    
  checkVictory: ->
    return if @world.age < 1
    for name, wave of @waves
      #console.log 'CATSYNC: waves unspawned', name, wave.length unless @world.age < 40
      return if wave.length  # Can't be finished until all waves have spawned.
    enemiesLeft = (t for t in @world.thangs when (t.team is 'ogres' or t.team is 'neutral') and t.exists and t.health > 0)
    if not enemiesLeft.length
      @setGoalState 'ogres-and-skeletons-die', 'success'
      @world.endWorld true, 1
    else
      console.log 'CATSYNC: enemies left', enemiesLeft.length, 'at', @world.age unless @world.age < 40
      console.log 'CATSYNC: enemiesLeft[0]', enemiesLeft[0].id, enemiesLeft[0].spriteName,'pos', JSON.stringify(enemiesLeft[0].pos) unless @world.age < 40
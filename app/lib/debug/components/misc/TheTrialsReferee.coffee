Component = require 'lib/world/component'

module.exports = class TheTrialsReferee extends Component
  @className: 'TheTrialsReferee'
  chooseAction: ->
    @checkVictory()
    @newGame = not @events['trial1_started'] and not @events['trial2_started'] and not @events['trial3_started'] ? true : false
     
    # Greeting
    if @eventConditions('greeting')
      @say "Brave adventurer, you are about to begin the trials of Mordrath"
 
    # Intro1
    else if @eventConditions('trial1_intro1')
      if not @events['trial1_intro1']
        @events['trial1_intro1'] = @world.age
        @spawnMushrooms(@spawnLocations.trial1)
      
      @say "To begin the first trial, pick all of the mushrooms around the Oasis of Marr."
        
    # Intro2
    else if @eventConditions('trial1_intro2')
      if not @events['trial1_intro2']
        @events['trial1_intro2'] = @world.age
        
      @say "This will gain the attention of the gods and force them to respond."
    
    # Trial1 Prep
    else if @eventConditions('trial1_prep')
      @events['trial1_started'] = @world.age
      @heroHeal()
      @say "You have awakened the old gods, prepare yourself for combat!"
    
    # Trial1 Started
    else if @eventConditions('trial1_started')
      wave = @waves.trial1[0]
      if wave and (@world.age - @events['trial1_started'] >= wave.time)
        @spawnWave(wave)
        @waves.trial1.shift()
    
    # Trial1 Complete
    else if @eventConditions('trial1_complete')
      if @enemiesCleared()
        @completed['trial1'] = true
        @say "Well done, Champion. You have beaten the first Trial. The Oasis of Anele awaits you"
        @spawnMushrooms(@spawnLocations.trial2)
    
    # Trial2 Prep
    else if @eventConditions('trial2_prep')
      @events['trial2_started'] = @world.age
      @heroHeal()
      @say "You have gained the attention of the gods, prepare yourself for combat!"
    
    # Trial2 Started
    else if @eventConditions('trial2_started')
      wave = @waves.trial2[0]
      if wave and @world.age - @events['trial2_started'] >= wave.time
        @spawnWave(wave)
        @waves.trial2.shift()

    # Trial2 Complete
    else if @eventConditions('trial2_complete')
      if @enemiesCleared()
        @completed['trial2'] = true
        @say "Congratulations for besting the second trial. Proceed to the Temple of Mirth"
        @spawnMushrooms(@spawnLocations.trial3)

    # Trial3 Prep
    else if @eventConditions('trial3_prep')
      @events['trial3_started'] = @world.age
      @heroHeal()
      @say "You are really upsetting the balance now, ready yourself!"
    
    # Trial3 Started
    else if @eventConditions('trial3_started')
      wave = @waves.trial3[0]
      if wave and @world.age - @events['trial3_started'] >= wave.time
        @spawnWave(wave)
        @waves.trial3.shift()

    # Trial3 Complete
    else if @eventConditions('trial3_complete')
      if @enemiesCleared()
        @completed['trial3'] = true
      if not @allEnemiesCleared()
        @say "You can not awaken the Oracle until you have dispatched all of her minions!"
    
    # Awakening the boss
    else if @completed['trial3'] and @allEnemiesCleared() and not @events.bossAwakened
      @events.bossAwakened = true
      @events['bossSpawn'] = @world.age
      @hero.health = @hero.maxHealth
      @say "Oh no, can you hear that? You have awaken something powerful and ancient!"
    
    # Final Boss
    else if @eventConditions('bossSpawn')
      # spawn final boss
      @events.bossEngaged = true
      oracle = @world.getThangByID 'Oracle of Zha'
      oracle.say "All my beautiful children! You will die infidel!"
      oracle.appearanceDelay = 0
      @say "I have healed you for the final battle. Defeat the Oracle!"
    else if @newGame
      @say ""
        
  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    @overseer = @world.getThangByID 'Trial Master'
    
    @overseer.isAttackable = false
    
    @completed =
      'trial1': false
      'trial2': false
      'trial3': false

    @events =
      'trial1_started': false
      'trial2_started': false
      'trial3_started': false
      'trial1_intro1': false
      'trial1_intro2': false
      'bossAwakened': false
      'bossSpawn': false
      'bossEngaged': false
        
    @eventDurations =
      "default": { time: 3 }
    
    @enemyUnits =
      M: ['ogre-munchkin-f', 'ogre-munchkin-m']
      C: ['ogre-scout-f', 'ogre-scout-m']
      T: ['ogre-thrower']
      O: ['oasis-guardian']
      S: ['ogre-shaman']
      F: ['ogre-f']
    
    @world.getSystem('Existence').buildTypePower['oasis-guardian'] = 49.8
    
    @waves =
      'trial1': [
        {time: 6, units: 'MCM'},
        {time: 12, units: 'CMTM'},
        {time: 18, units: 'MCMTS'}
        {time: 27, units: 'MCTCM'}
        {time: 39, units: 'MTO'}
      ],
      'trial2': [
        {time: 6, units: 'MCM'},
        {time: 12, units: 'CMTM'},
        {time: 18, units: 'MCMTS'}
        {time: 27, units: 'MCTCM'}
        {time: 39, units: 'MTO'}
      ],
      'trial3': [
        {time: 6, units: 'MCM'},
        {time: 12, units: 'CMTM'},
        {time: 18, units: 'MCMTS'}
        {time: 27, units: 'MCTCM'}
        {time: 39, units: 'MTO'}
      ]
    
    @spawnLocations =
      'trial1': [
        {x: 120, y: 19}
        {x: 128, y: 18}
        {x: 124, y: 23}
        {x: 125, y: 32}
        {x: 128, y: 27}
        {x: 132, y: 31}
        {x: 134, y: 16}
        {x: 149, y: 14}
        {x: 143, y: 36}
        {x: 152, y: 34}
        {x: 155, y: 30}
      ],
      'trial2': [
        {x: 13, y: 94}
        {x: 14, y: 100}
        {x: 8, y: 99}
        {x: 12, y: 107}
        {x: 16, y: 107}
        {x: 7, y: 111}
        {x: 16, y: 113}
        {x: 21, y: 116}
        {x: 7, y: 125}
        {x: 11, y: 124}
        {x: 14, y: 128}
        {x: 30, y: 130}
        {x: 31, y: 125}
        {x: 25, y: 129}
        {x: 40, y: 127}
        {x: 42, y: 131}
      ],
      'trial3': [
        {x: 101, y: 122}
        {x: 107, y: 121}
        {x: 120, y: 131}
        {x: 128, y: 129}
        {x: 134, y: 128}
        {x: 133, y: 124}
        {x: 137, y: 120}
        {x: 133, y: 114}
        {x: 138, y: 112}
        {x: 130, y: 108}
        {x: 125, y: 112}
      ]
  
  heroHeal: ->
    #
    # heroHeal
    #   | heals the hero, used after they eat the mushrooms to begin a trial
    #
    @hero.health = @hero.maxHealth
    @hero.sayWithoutBlocking("Fungus, it does a body good!")
  
  eventActive: (eventName) ->
    return (@events[eventName] and (@world.age - @events[eventName] <= @eventDurations.default.time))

  eventDelayPassed: (eventName) ->
    return (@events[eventName] and (@world.age - @events[eventName] >= @eventDurations.default.time))

  eventConditions: (eventName) ->
    switch eventName
      when "greeting" then return @newGame and @world.age <= @eventDurations.default.time
      when "trial1_intro1", "trial1_intro2" then return @newGame and (not @events[eventName] or @eventActive(eventName))
      when "trial1_prep" then return @newGame and @world.getSystem("Inventory").collectables < 1
      when "trial1_started" then return @waves.trial1[0] and @eventDelayPassed(eventName)
      when "trial1_complete" then return @events['trial1_started'] and not @waves.trial1[0] and not @completed['trial1']
      when "trial2_prep" then return not @events['trial2_started'] and @completed['trial1'] and @world.getSystem("Inventory").collectables < 1
      when "trial2_started" then return @waves.trial2[0] and @eventDelayPassed(eventName)
      when "trial2_complete" then return @events['trial2_started'] and not @waves.trial2[0] and not @completed['trial2']
      when "trial3_prep" then return not @events['trial3_started'] and @completed['trial2'] and @world.getSystem("Inventory").collectables < 1
      when "trial3_started" then return @waves.trial3[0] and @eventDelayPassed(eventName)
      when "trial3_complete" then return @events['trial3_started'] and not @waves.trial3[0] and not @completed['trial3']
      when "bossSpawn" then return @completed['trial3'] and @eventDelayPassed(eventName)

  currentProgress: ->
    #
    # currentProgress
    #   | returns the current trial the player is on
    #
    if @completed['trial1'] and @completed['trial2'] and @completed['trial3']
      return 4
    else if @completed['trial1'] and @completed['trial2']
      return 3
    else if @completed['trial1']
      return 2
    else
      return 1

  trialLocations: ->
    #
    # trialLocations
    #   | returns the spawn locations for the current trial
    #
    switch @currentProgress()
      when 1 then return @spawnLocations.trial1
      when 2 then return @spawnLocations.trial2
      when 3 then return @spawnLocations.trial3

  allEnemiesCleared: ->
    #
    # allEnemiesCleared
    #   | returns true if all enemies are cleared
    #
    enemies = (t for t in @world.getSystem("Combat").attackables when t.isAttackable and t.team is "ogres" and not t.dead and t isnt @hero)
    return enemies.length < 1

  enemiesCleared: ->
    #
    # enemiesCleared
    #   | returns true if no enemies are left at the spawn points or near the hero and all mini bosses are dead
    #
    trialLocations = @trialLocations()
    if trialLocations
      for unit in @world.getSystem("Combat").attackables when unit.team is 'ogres'
        for loc in trialLocations
          if loc.x is unit.pos.x and loc.y is unit.pos.y
            return false
        if @hero.distanceTo(unit) <= 40
          return false
      
      minibosses = (t for t in @world.thangs when t.type is 'oasis-guardian' and t.exists and t.health >= 0)
      return not minibosses.length > 0
  
  spawnMushrooms: (locations) ->
    #
    # spawnMushrooms
    #   | spawns all the mushrooms to start a trial
    #
    for mushroomPos in locations
      @buildXY "mushroom", mushroomPos.x, mushroomPos.y
      @performBuild()
  
  spawnWave: (wave) ->
    #
    # spawnWave
    #   | spawns a wave for a trial
    #
    units = (@enemyUnits[key] for key in wave.units)
    buildTypes = (choices[@world.rand.rand choices.length] for choices in units)
    trialLocations = @trialLocations()

    for buildType in buildTypes
      rand = Math.floor(@world.rand.randf2(0, trialLocations.length - 1))
      spawnPos = trialLocations[rand]

      buildx = spawnPos.x + 2 * (-0.5 + @world.rand.randf())
      buildy = spawnPos.y + 2 * (-0.5 + @world.rand.randf())
      newEnemy = @instabuild(buildType, buildx, buildy)
      if ((@currentProgress() is 1 or @currentProgress() is 2 or @currentProgress() is 3) and buildType is "oasis-guardian")
        if @currentProgress() is 1
          newEnemy.say("PUNY HUMAN... ME HUNGRY!")
        
        if @currentProgress() is 2
          newEnemy.say("RAAAAAAWWWR!")
        
        if @currentProgress() is 3
          newEnemy.say("SMASH! SMASH!")
        
  checkVictory: ->
    if @events['bossEngaged'] and @allEnemiesCleared()
      @setGoalState 'oracle-die', 'success'
      
    if @hero?.erroredOut and not @givenUpOnHero
      @givenUpOnHero = true
      @world.endWorld false, 6, true
      
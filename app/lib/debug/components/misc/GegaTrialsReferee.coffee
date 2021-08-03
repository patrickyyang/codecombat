Component = require 'lib/world/component'

module.exports = class GegaTrialsReferee extends Component
  @className: 'GegaTrialsReferee'
  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    @overseer = @world.getThangByID 'Trial Master'
    
    @overseer.isAttackable = false
    desertOfAgena: ->
      @desertCompleted =
        'trial1d': false
        'trial2d': false
        'trial3d': false
        'trial4d': false
  
      @desertEvents =
        'trial1d_started': false
        'trial2d_started': false
        'trial3d_started': false
        'trial4d_started': false
        'trial1_intro1': false
        'trial1_intro2': false
        
          
      @eventDurations =
        "default": { time: 3 }
      
      @enemyUnits =
        M: ['ogre-munchkin-f', 'ogre-munchkin-m']
        C: ['ogre-scout-f', 'ogre-scout-m']
        T: ['ogre-thrower']
        O: ['oasis-guardian']
        S: ['ogre-shaman']
        F: ['ogre-f']
        B: ['ogre-brawler']

      
      @waves =
        'trial1': [
          {time: 6, units: 'MCMFB'},
          {time: 12, units: 'CMTMC'},
          {time: 18, units: 'MCMTS'}
          {time: 27, units: 'MCTCM'}
          {time: 39, units: 'MTOSS'}
        ],
        'trial2': [
          {time: 6, units: 'MCMBS'},
          {time: 12, units: 'CMTMB'},
          {time: 18, units: 'MCMTS'}
          {time: 27, units: 'MCTCM'}
          {time: 39, units: 'MTOOS'}
        ],
        'trial3': [
          {time: 6, units: 'MCMBB'},
          {time: 12, units: 'CMTMF'},
          {time: 18, units: 'MCMTS'}
          {time: 27, units: 'MCTCM'}
          {time: 39, units: 'MTOSF'}
        ],
        'trial4': [
          {time: 6, units: 'BBBBB'},
          {time: 12, units: 'BBBBB'},
          {time: 18, units: 'BBBBB'}
          {time: 27, units: 'BBBBB'}
          {time: 39, units: 'BBBBB'}
        ]
        
      @spawnLocations =
      'trial1d': [
        {x: 141, y: 111}
        {x: 107, y: 117}
        {x: 140, y: 117}
        {x: 127, y: 116}
        {x: 128, y: 125}
        {x: 132, y: 31}
        {x: 134, y: 16}
        {x: 149, y: 14}
        {x: 143, y: 36}
        {x: 152, y: 34}
        {x: 155, y: 30}
      ],
      'trial2d': [
        {x: 48, y: 85}
        {x: 60, y: 85}
        {x: 52, y: 85}
        {x: 54, y: 85}
        {x: 56, y: 85}
        {x: 58, y: 85}
        {x: 70, y: 85}
        {x: 89, y: 85}
        {x: 67, y: 85}
        {x: 91, y: 85}
        {x: 73, y: 85}
        {x: 76, y: 85}
        {x: 79, y: 85}
        {x: 81, y: 85}
        {x: 82, y: 85}
        {x: 84, y: 85}
      ],
      'trial3d': [
        {x: 37, y: 62}
        {x: 56, y: 62}
        {x: 60, y: 62}
        {x: 64, y: 62}
        {x: 67, y: 62}
        {x: 74, y: 62}
        {x: 77, y: 62}
        {x: 81, y: 62}
        {x: 87, y: 62}
        {x: 102, y: 62}
      ],
      'trial4d': [
        {x: 131, y: 94}
        {x: 140, y: 86}
        {x: 143, y: 82}
      ]
      currentDesertProgress: ->
      if @completed['trial1d'] and @completed['trial2d'] and @completed['trial3d'] and @completed['trial4d']
        return 5
      else if @completed['trial1d'] and @completed['trial2d'] and @completed['trial3d']
        return 4
      else if @completed['trial1d'] and @completed['trial2d']
        return 3
      else if @completed['trial1d']
        return 2
      else
        return 1
      heroHeal: ->
        @hero.health = @hero.maxHealth
        @hero.sayWithoutBlocking('I feel AWEEEEEEEEESOME!')
      desertTrialLocations: ->
        switch @currentProgress()
          when 1 then return @spawnLocations.trial1d
          when 2 then return @spawnLocations.trial2d
          when 3 then return @spawnLocations.trial3d
          when 4 then return @spawnLocations.trial4d
        
      chooseDesertActions: ->
        if @eventConditions('greeting')
          @overseer.say('Brave adventurer, you are about to begin the grande Gega Trials! Ho ho ho...')
        else if @eventConditions('trial_intro1')
          @overseer.say('There are a total of 4 torture zones which you need to escape.')
        else if @eventConditions('trial_intro2')
          @overser.say('Defeat each and every zone to survive. Now we shall start with the Desert of Agena.')
        else if @eventConditions('trial1d_prep')
          @events['trial1d_started'] = @world.age
          @heroHeal()
          @overseer.say('Get, set, go go go!')
        else if @eventConditions('trial1d_started')
          @wave = @waves.trial1d[0]
          if wave and (@world.age - @events['trial1d_started'] >= wave.time)
            @spawnWave(wave)
            @waves.trial1d.shift()
        else if @eventConditions('trial1d_complete')
          if @enemiesCleared()
            @completed['trial1d'] = true
            @overseer.say('Good job. Now move down to begin the second trial.')
        else if @eventConditions('trial2d_prep')
          @events['trial2d_started'] = world.age
          @heroHeal()
          @overseer.say('The gods have now noticed a little pest - YOU!')
        else if @eventConditions('trial2d_started')
          @wave = @waves.trial2d[0]
          if wave and (@world.age - @events['trial2d_started'] >= wave.time)
            @spawnWave(wave)
            @waves.trial2d.shift()
        else if @eventConditions('trial2d_complete')
          if @enemiesCleared()
            @completed['trial2d'] = true
            @overseer.say('Great! Next, show them you"re the boss by moving to the third trial below.')
        else if @eventConditions('trial3d_prep')
          @events['trial3d_started'] = world.age
          @heroHeal()
          @overseer.say ('The gods are pretty angry by now. As a result, they will be sending hundreds of arrows towards you.')
        else if @eventConditions('trial3d_started')
          @wave = @waves.trial3d[0]
          if wave and (@world.age - @events['trial3d_started'] >= wave.time)
            @spawnWave(wave)
            @waves.trial3d.shift()
        else if @eventConditions('trial3d_compltete')
          if @enemiesCleared()
            @completed['trial3d'] = true
            @overseer.say('Move to the last trial, full of brawlers, to show that you deserve the right to rule the land.')
 
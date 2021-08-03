Component = require 'lib/world/component'

module.exports = class SiegeOfStoneholdReferee extends Component
  @className: 'SiegeOfStoneholdReferee'

  chooseAction: ->
    @setUpStonehold() unless @stoneholdSetUp
    t = @world.age
    wave = @waves[0]
    if wave and t >= wave.time
      @spawnWave wave
      @waves.shift()
    @controlMinion(minion) for minion in @built when minion.health > 0
    @controlHealer()
    @checkStoneholdVictory()


  setUpStonehold: ->
    @stoneholdSetUp = true
    @positions =
      center: { x: 66  , y: 70  }

      ne:     { x: 156 , y: 84  }
      ne1:    { x: 146 , y: 120 }
      ne2:    { x: 124 , y: 118 }

      se:     { x: 156 , y: 53  }
      se1:    { x: 142 , y: 33  }
      se2:    { x: 112 , y: 33  }

      n:      { x: 75  , y: 125 }
      n1:     { x: 75  , y: 115 }
      s:      { x: 58  , y: 6   }
      s1:     { x: 58  , y: 18  }
      s2:     { x: 65  , y: 22  }

      nw:     { x: 9   , y: 129 }
      nw1:    { x: 30  , y: 114 }
      sw:     { x: 9   , y: 6   }
      sw1:    { x: 30  , y: 28  }
    p = @positions
    @paths =
      NE_C: [p.ne, p.ne1, p.ne2]
      SE_C: [p.se, p.se1, p.se2]
      NW_C: [p.nw, p.nw1, p.n1]
      SW_C: [p.sw, p.sw1, p.s1]
      N_C:  [p.n, p.n1]
      S_C:  [p.s, p.s1, p.s2]
    P = @paths

    # M is Munchkin, T is Thrower, O is Ogre, F is Ogre Female, S is Ogre Shaman
    @waves = [
      {time: 1, paths: [P.NE_C], ogres: ['MMMMMMMMMMT', ]}
      {time: 3, paths: [P.SW_C], ogres: ['MMMMMM']}

      {time: 12, paths: [P.SE_C], ogres: ['MMMMMMM']}
      {time: 15, paths: [P.NW_C], ogres: ['MMMMMMMTT']}

      {time: 24, paths: [P.S_C], ogres: ['MMMMOO']}
      {time: 27, paths: [P.NE_C], ogres: ['MMMMMMMTT']}

      {time: 36, paths: [P.S_C], ogres: ['MMMMMMTT']}
      {time: 42, paths: [P.N_C], ogres: ['OOTT']}

      {time: 48, paths: [P.SE_C], ogres: ['MMMMMMMTT']}
      {time: 51, paths: [P.N_C], ogres: ['MMMMMMMOOTT']}

      {time: 62, paths: [P.S_C], ogres: ['MMMMMTT']}
      {time: 65, paths: [P.N_C], ogres: ['MMMMMOOTT']}

      {time: 74, paths: [P.S_C], ogres: ['MMMMMMTS']}
      {time: 77, paths: [P.NE_C], ogres: ['MMMMMOS']}

    ]
    
    @thoktar = @world.getThangByID 'Thoktar'
    @healMark = @world.getThangByID 'Heal Mark'
    
  spawnWave: (wave) ->
    ogreKeys = wave.ogres[@world.rand.rand wave.ogres.length]
    buildTypeChoices = ({M: ['ogre-munchkin-f', 'ogre-munchkin-m'], T: ['ogre-thrower'], O: ['ogre-m'], S: ['ogre-shaman'], F: ['ogre-f']}[key] for key in ogreKeys)
    buildTypes = (choices[@world.rand.rand choices.length] for choices in buildTypeChoices)
    path = wave.path = wave.paths[@world.rand.rand wave.paths.length]
    for buildType in buildTypes
      spawnPos = path[0]
      buildx = spawnPos.x + 1.5 * (-0.5 + @world.rand.randf())
      buildy = spawnPos.y + 3 * (-0.5 + @world.rand.randf())
      @buildXY buildType, buildx, buildy
      thang = @performBuild()
      thang.wave = wave
      thang.path = path.slice()
      #console.log 'Built', buildType, thang.id, 'at', thang.pos, 'at time', @world.age
      insults = ['Die, humans!', 'Take that!', 'Destroy them!', 'Go, minions!', 'Get their bones!', "Don't live!"]
      @thoktar.say insults[Math.floor @world.rand.randf() * insults.length]

  controlMinion: (minion) ->
    path = minion.path
    if path.length > 0
      waypoint = path[0]
      if waypoint
        minion.move waypoint
        if minion.distance(waypoint) < 4
          path.shift()
    else
      enemy = minion.getNearestEnemy()
      if enemy
        minion.attack enemy
      else
        minion.moveXY 66, 70

  checkStoneholdVictory: ->
    return unless @world.age > 80
    if @checkedVictoryAt
      if @world.age > @checkedVictoryAt + 2.5
        @thoktar.move {x: @thoktar.pos.x + 50, y: @thoktar.pos.y}
      return
    return if @checkedVictory
    ogresSurviving = (t for t in @world.thangs when t.team is 'ogres' and t.id isnt 'Thoktar' and t.health > 0).length
    if not ogresSurviving
      @setGoalState 'ogres-die', 'success'
      @world.endWorld true, 4
      @checkedVictoryAt = @world.age
      @thoktar.say "This isn't over!"

  # Heal the Hero when appropriate
  controlHealer: ->
    healer = @world.getThangByID 'Doctor'
    hero = @world.getThangByID 'Hero Placeholder'
    if hero.health < hero.maxHealth && hero.distanceTo(@healMark) < 3 && healer.canCast('heal')
      healer.cast('heal', hero)
      healer.say('Healed!')
      if healer.canCast("haste", hero)
        healer.cast("haste", hero)
      hero.wasHealed = true # This prevents a help script about the healer from displaying.
    else
      healer.setAction 'idle'
      healer.say(hero.spriteName+'! I can heal you!') if hero.health < (hero.maxHealth/2)

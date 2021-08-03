Component = require 'lib/world/component'

module.exports = class OasisReferee extends Component
  @className: 'OasisReferee'
  chooseAction: ->
    @setUpOasis() unless @oasisSetUp
    @spawnMinions()
    @controlMinions()
    @checkOasisVictory()

  setUpOasis: ->
    @oasisSetUp = true
    @leftX = 8
    @rightX = 72
    @bottomY = 0
    @topY = 60
    hero = @world.getThangByID 'Hero Placeholder'
    if hero.maxSpeed is 13
      hero.maxSpeed = 12  # It didn't really work at speed 13
    @yakTimeFactor = hero.maxSpeed / 8  # Make it so that if it was balanced at speed 8, it'll be balanced at any speed
    if @yakTimeFactor is 1.0625
      @yakTimeFactor = 1.1  # It didn't really work with speed 8.5.
    console.log 'got yakTimeFactor', @yakTimeFactor, 'from hero speed', hero.maxSpeed
    y1 = (if @world.rand.randf() < 0.5 then @bottomY - 3 else @topY + 3)
    y2 = if y1 == @topY + 3 then @bottomY - 3 else @topY + 3
    t = @world.age
    spawnOptions = [
      [
        { type: 'sand-yak', x: 15, y: y1, speed: .35, at: t+1, did: 0 }
        { type: 'sand-yak', x: 25, y: y2, speed: .65, at: t  , did: 0 }
        { type: 'sand-yak', x: 35, y: y2, speed: .35, at: t+2, did: 0 }
        { type: 'sand-yak', x: 45, y: y1, speed: .55, at: t  , did: 0 }
        { type: 'sand-yak', x: 55, y: y2, speed: .65, at: t+2, did: 0 }
        # Followers to fill space, they shouldn't affect play (much).
        { type: 'sand-yak', x: 25, y: y2, speed: .65, at: t+8, did: 0 }
        { type: 'sand-yak', x: 35, y: y2, speed: .35, at: t+7, did: 0 }
        { type: 'sand-yak', x: 45, y: y1, speed: .55, at: t+8, did: 0 }
        { type: 'sand-yak', x: 55, y: y2, speed: .37, at: t+9, did: 0 }
      ],
      [
        { type: 'sand-yak', x: 15, y: y2, speed: .40, at: t+2, did: 0 }
        { type: 'sand-yak', x: 20, y: y1, speed: .35, at: t+1, did: 0 }
        { type: 'sand-yak', x: 35, y: y2, speed: 1.05, at: t  , did: 0 }
        { type: 'sand-yak', x: 45, y: y2, speed: .52, at: t+1, did: 0 }
        { type: 'sand-yak', x: 55, y: y1, speed: .35, at: t+2, did: 0 }

        { type: 'sand-yak', x: 25, y: y1, speed: .35, at: t+7, did: 0 }
        { type: 'sand-yak', x: 35, y: y2, speed: .95, at: t+9, did: 0 }
        { type: 'sand-yak', x: 45, y: y2, speed: .52, at: t+10, did: 0 }
        { type: 'sand-yak', x: 55, y: y1, speed: .35, at: t+8, did: 0 }
      ],
    ]
    i = Math.floor @world.rand.randf() * spawnOptions.length
    console.log 'got spawn options', i
    @spawns = spawnOptions[i]
    
  spawnMinions: ->
    #return if @world.age > 30
    for spawn in @spawns
      if spawn.did * 10 < @world.age and @world.age >= spawn.at + spawn.did*10 / @yakTimeFactor
        @spawnMinion spawn

  spawnMinion: (spawn) ->
    spawn.did += 1
    buildType = spawn.type
    @buildXY buildType, spawn.x, spawn.y
    thang = @performBuild()
    thang.move x: spawn.x, y: (if spawn.y < 30 then @topY + 10 else @bottomY - 10)
    thang.maxSpeed *= @yakTimeFactor
    thang.currentSpeedRatio = spawn.speed
    if buildType is 'sand-yak'
      thang.scaleFactor = 1.20 + 1.05 * @world.rand.randf()
      thang.keepTrackedProperty 'scaleFactor'

  controlMinions: ->
    hero = @world.getThangByID 'Hero Placeholder'
    for minion in @built when minion.team
      aggroDistance = if minion.type is 'sand-yak' then 5 else 10
      if minion.pos.y > @topY + 3 or minion.pos.y < @bottomY - 3
        minion.setExists false
      else if (minion.distanceTo(hero) < aggroDistance) or minion.hadAttackedHero
        minion.attack hero
        minion.hadAttackedHero = true
        minion.specificAttackTarget = hero

  checkOasisVictory: ->
    return if @victoryChecked
    hero = @world.getThangByID 'Hero Placeholder'
    minionsAttacking = (t for t in @built when t.exists and t.health > 0 and t.hadAttackedHero).length
    if (not minionsAttacking or @world.age > 39.8) and hero.pos.x > @rightX - 10
      @victoryChecked = true
      @setGoalState 'get-to-oasis', 'success'
      @world.endWorld true, 1

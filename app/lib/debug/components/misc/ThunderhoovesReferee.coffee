Component = require 'lib/world/component'

module.exports = class ThunderhoovesReferee extends Component
  @className: 'ThunderhoovesReferee'
  chooseAction: ->
    @setUp() unless @didSetUp
    @spawnMinions()
    @controlMinions()
    @checkVictory()

  setUp: ->
    @didSetUp = true
    p = {
      H0:{ trigger:14, spawn:{ x:18, y:54 }, camp:{ x:18, y:30 } }
      L0:{ trigger:15, spawn:{ x:18, y: 8 }, camp:{ x:18, y:30 } }
      #This one is busted: H1:{ trigger:35, spawn:{ x:40, y:54 }, camp:{ x:40, y:30 } }
      L1:{ trigger:34, spawn:{ x:40, y: 8 }, camp:{ x:40, y:30 } }
      H2:{ trigger:54, spawn:{ x:60, y:54 }, camp:{ x:60, y:30 } }
      L2:{ trigger:55, spawn:{ x:60, y: 8 }, camp:{ x:60, y:30 } }
    }
    opts = [
      [ p.L0, p.L1, p.H2 ]
      [ p.L0, p.L1, p.L2 ]
      [ p.H0, p.L1, p.H2 ]
      [ p.H0, p.L1, p.L2 ]
    ]
    @waves = opts[@world.rand.rand opts.length]
    @wave = 0
    @oasis = { x:63, y:30 }
    @attackRange = 5
    hero = @world.getThangByID 'Hero Placeholder'
    @speedFactor = hero.maxSpeed / 8 # for scaling yak speeds against different heros

  spawnMinions: ->
    return if @wave >= @waves.length
    wave = @waves[@wave]
    hero = @world.getThangByID 'Hero Placeholder'
    if hero.pos.x > wave.trigger
      #console.log(@wave + ': ' + wave.spawn.x + ',' + wave.spawn.y)
      @buildXY('sand-yak', wave.spawn.x, wave.spawn.y)
      minion = @performBuild()
      minion.maxSpeed *= @speedFactor
      minion.currentSpeedRatio = .90
      minion.scaleFactor = 1.25 + 1.00 * @world.rand.randf()
      minion.reachedCamp = false
      minion.reachedOasis = false
      minion.attacking = false
      minion.campPoint = wave.camp
      minion.move(minion.campPoint)
      @wave++

  controlMinions: ->
    hero = @world.getThangByID 'Hero Placeholder'
    for minion in @built when minion.campPoint
      if minion.attacking or minion.distanceTo(hero.pos) < @attackRange
        minion.attack(hero)
        minion.attacking = true

      if not minion.reachedCamp
        if minion.distanceTo(minion.campPoint) < 3
          minion.reachedCamp = true
        else
          minion.move(minion.campPoint)

      else if not minion.reachedOasis
        if minion.distanceTo(@oasis) < 3
          minion.reachedOasis = true
        else
          minion.move(@oasis)

  checkVictory: ->
    return if @world.victory?
    return if @wave < @waves.length
    return unless @world.getGoalState('get-to-oasis') is 'success'
    for minion in @built when minion.health > 0
      if minion.attacking or minion.reachedCamp
        @checkingVictorySince = null
      if minion.lastPos
        d = minion.lastPos.distance minion.pos
        minion.blocked ||= d < 0.2
      minion.lastPos = minion.pos.copy()
      return unless minion.blocked
    @checkingVictorySince ?= @world.age
    if @world.age > @checkingVictorySince + 0.5
      @world.endWorld true, 0.1

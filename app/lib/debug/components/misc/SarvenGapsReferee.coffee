Component = require 'lib/world/component'

module.exports = class SarvenGapsReferee extends Component
  @className: 'SarvenGapsReferee'
  chooseAction: ->
    @setUp() unless @sarvenGapsSetUp
    @spawnMinions()
    @controlMinions()
    @checkVictory()

  setUp: ->
    @sarvenGapsSetUp = true
    @waves = [
      { trigger:99, spawn:{ x:46, y:51 }, camp:{ x:14, y:51 } }
      { trigger:43, spawn:{ x:46, y:31 }, camp:{ x:14, y:31 } }
      { trigger:24, spawn:{ x:46, y:11 }, camp:{ x:14, y:11 } }
    ]
    @wave = 0
    @waveMin = 2
    @waveMax = 4

  spawnMinions: ->
    return if @wave >= @waves.length
    hero = @world.getThangByID 'Hero Placeholder'
    wave = @waves[@wave]
    return if hero.pos.y > wave.trigger
    @wave++
    waveSize = @waveMin + Math.floor(@world.rand.randf() * (@waveMax - @waveMin))
    for i in [0...waveSize]
      angle = @world.rand.randf() * Math.PI * 2
      sx = wave.spawn.x + i * 2
      sy = wave.spawn.y
      console.log(@wave + ', ' + i + '/' + waveSize + ': ' + sx + ',' + sy)
      @build('ogre-m')
      minion = @performBuild()
      minion.pos.x = sx
      minion.pos.y = sy
      minion.campPoint = wave.camp
      minion.move(minion.campPoint)

  controlMinions: ->
    hero = @world.getThangByID 'Hero Placeholder'
    for minion in @built when minion.campPoint
      if minion.canSee(hero)
        minion.attack(hero)
      else
        minion.move(minion.campPoint)

  checkVictory: ->
    return if @victoryChecked
    return if @wave < @waves.length
    return unless @world.getGoalState('get-to-oasis') is 'success'
    for minion in @built when minion.health > 0
      if minion.pos.x < 18
        @checkingVictorySince = null
      return unless 18 < minion.pos.x < 30
      minion.blocked ||= minion.velocity.x > -1 and Math.abs(minion.velocity.y) < 1
      return unless minion.blocked
    @checkingVictorySince ?= @world.age
    if @world.age > @checkingVictorySince + 0.5
      @world.endWorld true, 0.1

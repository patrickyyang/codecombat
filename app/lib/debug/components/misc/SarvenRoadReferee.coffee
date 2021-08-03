Component = require 'lib/world/component'

module.exports = class SarvenRoadReferee extends Component
  @className: 'SarvenRoadReferee'
  chooseAction: ->
    @setUpSarvenRoad() unless @sarvenRoadSetUp
    @spawnMinions()
    @controlMinions()
    @checkSarvenRoadVictory()

  setUpSarvenRoad: ->
    @sarvenRoadSetUp = true
    p = {
      H0:{ trigger:{ x: 0, y: 0 }, spawn:{ x:-1, y:23 }, camp:{ x:10, y:19 } }
      L0:{ trigger:{ x: 0, y: 0 }, spawn:{ x:27, y: 6 }, camp:{ x:19, y:17 } }
      H1:{ trigger:{ x:14, y:14 }, spawn:{ x: 0, y:39 }, camp:{ x:21, y:34 } }
      L1:{ trigger:{ x:12, y:12 }, spawn:{ x:63, y:19 }, camp:{ x:38, y:28 } }
      H2:{ trigger:{ x:22, y:22 }, spawn:{ x:15, y:58 }, camp:{ x:37, y:47 } }
      L2:{ trigger:{ x:28, y:28 }, spawn:{ x:68, y:40 }, camp:{ x:48, y:46 } }
    }
    opts = [
      [ p.H0, p.H1, p.L2, p.L2 ]
      [ p.L0, p.L1, p.H2, p.H2 ]
      [ p.H0, p.L1, p.H2, p.H2 ]
      [ p.L0, p.H1, p.L2, p.H2 ]
    ]
    @waves = opts[@world.rand.rand opts.length]
    @wave = 0

  spawnMinions: ->
    return if @wave >= @waves.length
    wave = @waves[@wave]
    hero = @world.getThangByID 'Hero Placeholder'
    if hero.pos.x > wave.trigger.x and hero.pos.y > wave.trigger.y
      #console.log(@wave + ': ' + wave.spawn.x + ',' + wave.spawn.y)
      buildType = if @world.rand.randf() < 0.5 then 'ogre-scout-m' else 'ogre-scout-f'
      @buildXY(buildType, wave.spawn.x, wave.spawn.y)
      minion = @performBuild()
      minion.reachedCamp = false
      minion.campPoint = wave.camp
      minion.move(minion.campPoint)
      @wave++

  controlMinions: ->
    hero = @world.getThangByID 'Hero Placeholder'
    for minion in @built when minion.campPoint
      if minion.distanceTo(minion.campPoint) < 3
        minion.move(minion.campPoint)
      else
        minion.reachedCamp = true
      if minion.reachedCamp and minion.canSee(hero)
        minion.attack(hero)

  checkSarvenRoadVictory: ->
    if @wave is @waves.length and not (t for t in @built when t.health > 0).length
      @setGoalState 'ogres-die', 'success'
    return if @world.victory?
    return unless @getGoalState('get-to-oasis') is 'success'
    if @getGoalState('ogres-die') is 'success'
      @world.endWorld true, 1
      
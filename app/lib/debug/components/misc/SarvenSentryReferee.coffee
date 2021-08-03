Component = require 'lib/world/component'

module.exports = class SarvenSentryReferee extends Component
  @className: 'SarvenSentryReferee'
  chooseAction: ->
    @setUp() unless @didSetUp
    @scoutWarning()
    @spawnMinions()
    @controlMinions()
    @checkVictory()

  setUp: ->
    @didSetUp = true
    @victoryOgres = false
    @victoryHumans = false
    @victoryYaks = false
    @warnings = {
      'ogre-m': [
        'Ogre coming! Black, trap!'
        'Yikes! Ogre here! Black, trap.'
        'Ogre! Heads up. Black–trap!'
      ],
      'sand-yak': [
        'Sand Yak coming! Green, fence.'
        'Sand Yak. Green–fence!'
        'Here, Sand Yak! Green for fence.'
      ],
    }

    # this array has one extra element, so the balance will feel a little more random from seed to seed.
    bt = [ 'ogre-m', 'ogre-m', 'ogre-m', 'ogre-m', 'sand-yak', 'sand-yak', 'sand-yak', 'sand-yak' ]
    for i in [bt.length-1..1]
      j = @world.rand.rand(i-1)
      t = bt[j]
      bt[j] = bt[i]
      bt[i] = t

    @waves = [
      { scout:'Mira',     spawn:{ x:62, y:70 }, camp:{ x:53, y:58 }, type:bt[0], warned:false }
      { scout:'Quinn',    spawn:{ x:80, y:38 }, camp:{ x:70, y:38 }, type:bt[1], warned:false }
      { scout:'Simon',    spawn:{ x:80, y: 8 }, camp:{ x:59, y:12 }, type:bt[2], warned:false }
      { scout:'Omar',     spawn:{ x:42, y:-3 }, camp:{ x:33, y:13 }, type:bt[3], warned:false }
      { scout:'Fidsdale', spawn:{ x: 1, y:18 }, camp:{ x:20, y:29 }, type:bt[4], warned:false }
      { scout:'Slyvos',   spawn:{ x: 0, y:50 }, camp:{ x:20, y:49 }, type:bt[5], warned:false }
      { scout:'Rowan',    spawn:{ x:28, y:71 }, camp:{ x:31, y:55 }, type:bt[6], warned:false }
    ]
    for i in [@waves.length-1..1]
      j = @world.rand.rand(i-1)
      t = @waves[j]
      @waves[j] = @waves[i]
      @waves[i] = t
      xMarker = @world.getThangByID(@waves[j].scout + ' X')
      xMarker.addTrackedProperties ['bobHeight', 'number']
      xMarker.keepTrackedProperty 'bobHeight'
    @waveDelay = 10
    @waveWarningDelay = 10
    @waveTime = @waveWarningDelay + 1
    @totalWaves = @waves.length
    @totalYaks = (y for y in bt[0..6] when y == 'sand-yak').length

  scoutWarning: ->
    return if @waves.length == 0
    return if @waves[0].warned
    return if @world.age < @waveTime - @waveWarningDelay
    @waves[0].warned = true
    scout = @world.getThangByID(@waves[0].scout)
    warnings = @warnings[@waves[0].type]
    scout.say(warnings[@world.rand.rand warnings.length])
    @world.getThangByID(scout.id + ' X').bobHeight = 1

  spawnMinions: ->
    return if @waves.length == 0
    return if @world.age < @waveTime
    wave = @waves[0]
    @waves.shift()
    @waveTime = @world.age + @waveDelay
    @build(wave.type)
    minion = @performBuild()
    minion.pos.x = wave.spawn.x
    minion.pos.y = wave.spawn.y
    minion.campPoint = wave.camp
    minion.move(minion.campPoint)
    @world.getThangByID(wave.scout + ' X').bobHeight = 0

  controlMinions: ->
    hero = @world.getThangByID 'Hero Placeholder'
    for minion in @built when minion.campPoint
      enemy = minion.findNearestEnemy()
      shouldAttack = enemy and minion.canSee(enemy) and minion.hitCampPoint
      if shouldAttack
        minion.attack(enemy)
      else
        if minion.distanceTo(minion.campPoint) > 3
          minion.move(minion.campPoint)
        else
          minion.hitCampPoint = true

  checkVictory: ->
    return unless @world.age > @waveDelay * @totalWaves
    return unless @waves.length == 0
    return if @victoryOgres and @victoryHumans and @victoryYaks
    ogresSurviving = (t for t in @world.thangs when t.team is 'ogres' and t.health > 0).length
    if ogresSurviving == 0 and not @victoryOgres
      console.log @world.age, 'victory ogres'
      @setGoalState 'ogres-die', 'success'
      @victoryOgres = true
    humansSurviving = (t for t in @world.thangs when t.team is 'humans' and t.health > 0).length
    if humansSurviving >= 8 and not @victoryHumans
      console.log @world.age, 'victory humans'
      @victoryHumans = true
    yaks = (t for t in @world.thangs when t.type is 'sand-yak')
    fences = (t for t in @world.thangs when t.spriteName is 'Fence Wall')
    yaksFenced = 0
    for yak in yaks
      distanceToFence = Infinity
      for fence in fences
        distanceToFence = Math.min distanceToFence, yak.distance(fence)
      if yak.dead or distanceToFence < 8
        ++yaksFenced
    if yaksFenced >= @totalYaks and not @victoryYaks
      console.log @world.age, 'victory yaks'
      @setGoalState 'yaks-fenced', 'success'
      @victoryYaks = true
    if @victoryOgres and @victoryHumans and @victoryYaks
      @world.endWorld true, 1

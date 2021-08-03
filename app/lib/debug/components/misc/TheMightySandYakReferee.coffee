Component = require 'lib/world/component'

module.exports = class TheMightySandYakReferee extends Component
  @className: 'TheMightySandYakReferee'
  chooseAction: ->
    @setUpTheMightySandYak() unless @theMightySandYakSetUp
    @spawnMinion()
    @controlMinions()
    @checkDodges()
    @checkTheMightySandYakVictory()
    @preventSlide()

  setUpTheMightySandYak: ->
    @theMightySandYakSetUp = true
    @bottomY = 0
    @topY = 60
    @spawnTime = @world.age + 1
    @dodgeDistance = 10
    @attackDistance = 5
    @yakDodgeGoal = 4
    @yakDodgeTotal = 0
    @yaksDispatchedByX = {}
    hero = @world.getThangByID 'Hero Placeholder'

  spawnMinion: ->
    return if @world.age < @waveTime
    @waveTime = @world.age + (3.5 + 1.0 * @world.rand.randf())
    hero = @world.getThangByID 'Hero Placeholder'
    return if @yaksDispatchedByX[Math.round hero.pos.x]?.health > 0
    yakPos = x: hero.pos.x, y: (if @world.rand.randf() < 0.5 then @bottomY - 3 else @topY + 3)
    @buildXY 'sand-yak', yakPos.x, yakPos.y
    thang = @performBuild()
    thang.move x: yakPos.x, y: (if yakPos.y < 30 then @topY + 10 else @bottomY - 10)
    thang.currentSpeedRatio = 0.25 + 0.30 * @world.rand.randf()
    thang.scaleFactor = 1.00 + 1.25 * @world.rand.randf()
    thang.keepTrackedProperty 'scaleFactor'
    thang.heroEncountered = false
    thang.heroDodged = false
    @yaksDispatchedByX[Math.round hero.pos.x] = thang

  controlMinions: ->
    hero = @world.getThangByID 'Hero Placeholder'
    for minion in @built when minion.team
      if not minion.heroEncountered and (minion.pos.y > @topY + 5 or minion.pos.y < @bottomY - 5)
        minion.setExists false
      else if (minion.distanceTo(hero) < @attackDistance) or minion.hadAttackedHero
        minion.attack hero
        minion.hadAttackedHero = true
        minion.specificAttackTarget = hero

  checkDodges: ->
    hero = @world.getThangByID 'Hero Placeholder'
    for minion in @built when minion.team
      mdist = minion.distanceTo(hero)
      if not minion.heroEncountered
        if mdist < @dodgeDistance
          minion.heroEncountered = true
          console.log('encounter ' + minion + ' ' + mdist)
      if minion.heroEncountered and not minion.heroDodged
        if mdist > @dodgeDistance and not minion.hadAttackedHero
          minion.heroDodged = true
          console.log('dodge ' + minion + ' ' + mdist)
          @yakDodgeTotal++

  checkTheMightySandYakVictory: ->
    return if @victoryChecked
    hero = @world.getThangByID 'Hero Placeholder'
    yaksAttacking = (t for t in @built when t.exists and t.health > 0 and t.hadAttackedHero).length
    if @yakDodgeTotal >= @yakDodgeGoal and not yaksAttacking
      @victoryChecked = true
      @setGoalState 'dodge-yaks', 'success'
      @world.endWorld true, 1

  preventSlide: ->
    hero = @world.getThangByID 'Hero Placeholder'
    if hero.action is 'idle'
      hero.brake()
      
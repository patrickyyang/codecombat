Component = require 'lib/world/component'

module.exports = class KeepingTimeReferee extends Component
  @className: 'KeepingTimeReferee'

  chooseAction: ->
    @controlRanger()
    @clearDeadPalisades()

  setUpLevel: ->
    @victoryCoins = false
    @victoryOgres = false
    @victorySurvive = true
    @coinTime = 10
    @raidTime = 30
    @naria = @world.getThangByID 'Naria'
    @naria.didAnnounceStart = false
    @naria.didAnnounceCoins = false
    @naria.didAnnounceRaid = false
    @palisades = (t for t in @world.thangs when t.type is 'palisade')

  controlRanger: ->
    if not @naria.didAnnounceStart
      @naria.didAnnounceStart = true
      @naria.say('We\'re under attack!')
    if @world.age > @coinTime and not @naria.didAnnounceCoins
      @naria.didAnnounceCoins = true
      @naria.say('Grab some coins so we can hire troops!')
    if 28 < @world.age < 30
      @naria.move x: @naria.pos.x + 10, y: @naria.pos.y
    if @world.age > @raidTime and not @naria.didAnnounceRaid
      @naria.didAnnounceRaid = true
      gold = Math.floor @hero.gold
      nSoldiers = Math.min 16, Math.floor(gold / 20)
      @naria.move 
      @naria.say(gold + ' gold buys ' + nSoldiers + ' soldiers. Everyone, attack!')
      troops = (thang for thang in @world.thangs when thang.appearanceDelay and thang.team is 'humans')
      troops = @world.rand.shuffle troops
      for thang in troops
        if --nSoldiers < 0
          thang.exists = false
          thang.appearanceDelay = 9001  # Didn't hire you!
          
  clearDeadPalisades: ->
    for t in @palisades when t.dead
      t.setExists false

  checkVictory: ->
    hero = @world.getThangByID 'Hero Placeholder'
    if @naria.health <= 0 or hero.health <= 0
      @victorySurvive = false

    return unless @world.age > @coinTime
    if hero.gold > 0 and not @victoryCoins
      @victoryCoins = true
      @setGoalState 'collect-coins', 'success'

    return unless @world.age > @raidTime
    livingOgres = (o for o in @world.thangs when o.team == 'ogres' and o.health > 0)
    if livingOgres.length == 0 and not @victoryOgres
      @victoryOgres = true
      @setGoalState 'ogres-die', 'success'

    if @victorySurvive and @victoryCoins and @victoryOgres
      @world.endWorld true, 1

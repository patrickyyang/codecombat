Component = require 'lib/world/component'

module.exports = class PowerBoostDietReferee extends Component
  @className: 'PowerBoostDietReferee'
  chooseAction: ->
    @configure()
    @decrementTimers()
    @checkVictory()
    @checkMushroom()
    
    if @keeper.target is @hero and not @hero.hasEffect("grow")
      @keeper.say? "Ha ha, puny weakling... You don't stand a chance!"
  
  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    @cave = @world.getThangByID 'Cave Referee'
    @keeper = @world.getThangByID 'Dungeon Keeper'
    
    @events =
      'powerboost': false
    
    @timers =
      "powerBoostTimer": 0
  
  configure: ->
    return unless not @configured
    
    @originalStats =
      'maxHealth': @hero.maxHealth
      'attackDamage': @hero.attackDamage
    
    @configured = true
  
  decrementTimers: ->
    for name, timer of @timers
      @timers[name] -= @world.dt
  
  checkMushroom: ->
    #
    # checkMushroom
    #   | checks if the player has collected the mushroom and apply powerboost if so
    #
    mushroom = (t for t in @world.thangs when t.spriteName is 'Mushroom' and t.exists)
    if mushroom.length < 1
      @activatePowerBoost()
  
  activatePowerBoost: ->
    #
    # activatePowerBoost
    #   | activates the power boost
    #
    return unless not @events.powerboost
    @events.powerboost = true
    @setGoalState 'boost', 'success'
    @castCustomGrow()
    
    # boost hero so he can kill the boss
    @hero.maxHealth += 50
    @hero.health = @hero.maxHealth
    @hero.attackDamage *= 4
    @hero.addTrackedProperties ['health', 'number']
    @hero.keepTrackedProperty 'health'
    @hero.addTrackedProperties ['attackDamage', 'number']
    @hero.keepTrackedProperty 'attackDamage'

    @timers.powerBoostTimer = 1
  
  castCustomGrow: ->
    #
    # castCustomGrow
    #   | casts customized grow effect on player
    #
    @spells["grow"].duration = 500
    @spells["grow"].speedFactor = 3
    @cast("grow", @hero)
    @["perform_grow"]()
    @cave.setTarget null
    @cave.setAction "idle"
  
  checkVictory: ->
    if @hero.health <= 0
      @setGoalState 'defeat', 'failure'
    else if @keeper.health <= 0
      @setGoalState 'defeat', 'success'
    else if @hero.gold >= 30
      @setGoalState 'treasure', 'success'
  
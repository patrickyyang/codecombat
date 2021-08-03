Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class DeadlyDungeonRescueReferee extends Component
  @className: 'DeadlyDungeonRescueReferee'
  chooseAction: ->
    @configure()
    @decrementTimers()
    @checkVictory()
    @checkDoors()
    @jibberJabber()
  
    if @rectangles['torture_chamber'].containsPoint @hero.pos
      @triggerFollow = true
    else if @triggerFollow
      @actors.peasant.isAttackable = true
      if @hero.distanceTo(@actors.peasant) > 10
        @actors.peasant.move(Vector.subtract(@actors.peasant.pos, @hero.pos).normalize().multiply(10).add(@hero.pos))
    
  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    
    @actors =
      "peasant": @world.getThangByID 'Tortured Peasant'
      "torturemaster": @world.getThangByID 'Torture Master'
      "grug": @world.getThangByID 'Grug'
      "smerk": @world.getThangByID 'Smerk'
      "brawler": @world.getThangByID 'Dungeon Brawler'
    
    @timers =
      "brawlerTimer": 0
    
    @doors = [
      @world.getThangByID 'North Vault Door'
      @world.getThangByID 'South Vault Door'
      @world.getThangByID 'Torture Room Door'
      @world.getThangByID 'Exit Door'
    ]
    
    for door in @doors
      door.showsName = false
      door.addTrackedProperties ['showsName', 'boolean']
      door.keepTrackedProperty 'showsName'
    
    @actors.peasant.isAttackable = false
    @triggerFollow = false

  configure: ->
    return unless not @configured
    
    @inventorySystem = @world.getSystem("Inventory")
    for team in ['humans', 'ogres']
      @inventorySystem.teamGold[team].income = 0
      
    @configured = true
  
  decrementTimers: ->
    for name, timer of @timers
      @timers[name] -= @world.dt
  
  checkDoors: ->
    #
    # checkDoors
    #   | if the player gets close to a door, display it's name
    #
    for door in @doors
      if @hero.distanceTo(door) <= 35
        door.showsName = true
    
  jibberJabber: ->
    now = Math.round(@world.age)
    emotes = [
      {time: 10, actor: @actors.peasant, message: "Please, I can't take anymore of it!"}
      {time: 13, actor: @actors.torturemaster, message: "Silence! You will give me the information I need"}
      {time: 18, actor: @actors.grug, message: "How did I get stuck on the night shift? *sigh*"}
      {time: 27, actor: @actors.smerk, message: "Wait! What's that? ... oh just a rat"}
      {time: 45, actor: @actors.torturemaster, message: "Hmm, let's try using these rusted spikes now.."}
      {time: 47, actor: @actors.peasant, message: "Urggrh!!"}
      {time: 54, actor: @actors.peasant, message: "*sobs*"}
      {time: 59, actor: @actors.grug, message: "*whistles*"}
      {time: 68, actor: @actors.smerk, message: "*hums*"}
      {time: 75, actor: @actors.grug, message: "*whistles*"}
      {time: 90, actor: @actors.peasant, message: "*sobs*"}
      {time: 118, actor: @actors.peasant, message: "*sobs*"}
    ]
    
    for emote in emotes
      if now is emote.time
        emote.actor.say emote.message
  
  checkVictory: ->
    if @rectangles['exit'].containsPoint(@hero.pos) and @triggerFollow and @actors.peasant.health > 0
      @setGoalState 'escape', 'success'
      @setGoalState 'stealth', 'success'
    else if @actors.peasant.health < 1
      @setGoalState 'escape', 'failure'
    else if @actors.grug.health < 1 or @actors.smerk.health < 1
      if @actors.grug.health < 1 and not @timers.brawlerTimer
        @actors.brawler.pos.x = @actors.grug.pos.x
        @actors.brawler.pos.y = @actors.grug.pos.y
        @hero.isAttackable = false
        @timers.brawlerTimer = 0.7
        @actors.brawler.appearanceDelay = 0
        @actors.brawler.say "HUMAN HURT GRUG... DIE!!"
      else if @actors.smerk.health < 1 and not @timers.brawlerTimer
        @actors.brawler.pos.x = @actors.smerk.pos.x
        @actors.brawler.pos.y = @actors.smerk.pos.y
        @hero.isAttackable = false
        @timers.brawlerTimer = 0.7
        @actors.brawler.appearanceDelay = 0
        @actors.brawler.say "HUMAN HURT SMERK... DIE!!"
      else if @timers.brawlerTimer and @timers.brawlerTimer <= 0
        @hero.isAttackable = true
        
      @setGoalState 'stealth', 'failure'
    else if @hero.gold >= 52
      @setGoalState 'loot', 'success'
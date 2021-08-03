Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class SarvenRescueReferee extends Component
  @className: 'SarvenRescueReferee'
  chooseAction: ->
    @configure()
    @checkVictory()
    @checkPotions()
    @checkPatrols()
    @jibberJabber()
    
    if @actors.banditLeader.health <= 0 and @actors.banditMarauder.health <= 0 and @actors.banditLooter.health <= 0 and @actors.banditWanderer.health <= 0 and not @triggerFollow
      @triggerFollow = true
    else if @triggerFollow and not @actors.peasant.isAttackable
      @actors.peasant.say "Thank you for saving me! Lead the way!"
      @actors.peasant.isAttackable = true
      @instabuild('x-mark-red', 22, 104)
    else if @triggerFollow
      if @hero.distanceTo(@actors.peasant) > 7
        @actors.peasant.move(Vector.subtract(@actors.peasant.pos, @hero.pos).normalize().multiply(7).add(@hero.pos))
    else if @actors.banditLeader.target is @hero
      @actors.banditLeader.say? "Kill the intruder!"
    
  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    @statue = @world.getThangByID 'Vision of Referee'
    
    @actors = 
      "peasant": @world.getThangByID 'Captured Peasant'
      "patrolling": @world.getThangByID 'Patrolling Bandit'
      "wandering": @world.getThangByID 'Wandering Bandit'
      "scouring": @world.getThangByID 'Scouring Bandit'
      "banditLeader": @world.getThangByID 'Bandit Leader'
      "banditMarauder": @world.getThangByID 'Bandit Marauder'
      "banditLooter": @world.getThangByID 'Bandit Looter'
      "banditWanderer": @world.getThangByID 'Bandit Wanderer'
      "sandyak": @world.getThangByID 'Ofgar'
    
    @patrolSpawns =
      'patrolling': false
      'wandering': false
      'scouring': false
    
    @potionEffects = [
      "grow"
      "shrink"
      "haste"
      "slow"
      "regen"
      "heal"
    ]
    
    @lastPotion = false
    @chestLooted = false
    @killedYak = false
    @actors.peasant.isAttackable = false
    @triggerFollow = false
  
  configure: ->
    return unless not @configured
    @buffScouts()
    @configured = true
  
  jibberJabber: ->
    now = Math.round(@world.age)
    emotes = [
      {time: 10, actor: @actors.peasant, message: "Please, I just want to go home!"}
      {time: 16, actor: @actors.banditLeader, message: "We aren't finished with you yet"}
      {time: 22, actor: @actors.peasant, message: "I don't have any valuables, I swear!"}
    ]
    
    for emote in emotes
      if now is emote.time
        emote.actor.say emote.message
  
  buffScouts: ->
    #
    # buffScouts
    #   | sets how many bodyguards the patrols will get based on hero max health
    #
    @numBodyguardsSpawn = if @hero.maxHealth <= 1000 then 1 else if @hero.maxHealth <= 1500 then 3 else 4
  
  checkPatrols: ->
    #
    # checkPatrols
    #   | if any of the patrols set the player as their target, activate their bodyguard(s)
    #
    if @actors.patrolling.target is @hero and not @patrolSpawns.patrolling
      for i in [1..@numBodyguardsSpawn] by 1
        @spawnBodyguard(@actors.patrolling)
      
      @actors.patrolling.say? "Enemy spotted!"
      @patrolSpawns.patrolling = true
    else if @actors.wandering.target is @hero and not @patrolSpawns.wandering
      for i in [1..@numBodyguardsSpawn] by 1
        @spawnBodyguard(@actors.wandering)
      
      @actors.wandering.say? "Enemy spotted!"
      @patrolSpawns.wandering = true
    else if @actors.scouring.target is @hero and not @patrolSpawns.scouring
      for i in [1..@numBodyguardsSpawn] by 1
        @spawnBodyguard(@actors.scouring)
      
      @actors.scouring.say? "Enemy spotted!"
      @patrolSpawns.scouring = true
  
  spawnBodyguard: (patrol) ->
    #
    # spawnBodyguard
    #   | spawns a bodyguard for a patrolling unit
    #
    r1 = @world.rand.randf2(-1, 2)
    r2 = @world.rand.randf2(-1, 2)
    v = Vector.subtract(patrol.pos, @hero.pos).normalize().multiply(4).add(patrol.pos)
    bodyguard = @instabuild('ogre-thrower', v.x + r1, v.y + r2)
    bodyguard.attack @hero
  
  checkChest: ->
    #
    # checkChest
    #   | returns false if the chest has been looted
    #
    chests = (t for t in @world.thangs when t.spriteName is 'Ogre Treasure Chest' and t.exists)
    return not chests.length < 1
  
  checkPotions: ->
    #
    # checkPotions
    #   | checks if the player picked up a potion and activates it
    #
    potions = (t for t in @world.thangs when t.spriteName is 'Health Potion Medium' and t.exists)
    if not @potions
      @potions = potions.length
    else if potions.length < @potions
      r = Math.round(@world.rand.randf2(0, 5))
      if @lastPotion
        while r is @lastPotion
          r = Math.round(@world.rand.randf2(0, 5))
          
      @activatePotion(r)
      @potions = potions.length
  
  activatePotion: (r) ->
    #
    # activatePotion
    #   | activates a potion the player just picked up
    #
    if @potionEffects[r] != "slow" and @potionEffects[r] != "heal" and @potionEffects[r] != "grow"
      @spells[@potionEffects[r]].duration = 10
    
    @cast(@potionEffects[r], @hero)
    @["perform_" + @potionEffects[r]]()
    @statue.setTarget null
    @statue.setAction "idle"
    @lastPotion = r
  
  checkVictory: ->
    if @actors.peasant.health <= 0 or @hero.health <= 0
      @setGoalState 'escape', 'failure'
    else if @actors.sandyak.health <= 0 and not @killedYak
      @setGoalState 'yak', 'success'
      @killedYak = true
    else if not @checkChest() and not @chestLooted
      @setGoalState 'treasure', 'success'
      @chestLooted = true
    else if @rectangles['exit'].containsPoint @hero.pos
      if @actors.peasant.health > 0 and @hero.distance(@actors.peasant) > 15 and @triggerFollow and @actors.peasant.isAttackable
        @actors.peasant.pos = Vector.subtract(@actors.peasant.pos, @hero.pos).normalize().multiply(7).add(@hero.pos)
      if @rectangles['exit'].containsPoint @actors.peasant.pos
        @setGoalState 'escape', 'success'
      
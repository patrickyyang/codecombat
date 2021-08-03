Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class WildHorsesReferee extends Component
  @className: 'WildHorsesReferee'
  chooseAction: ->
    @configure()
    @decrementTimers()
    @horsesRoutine()
  
  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    @referee = @world.getThangByID 'Referee Horse'
    
    @horseFollowing = false
    @tagHorse = false
    @numHorses = 6
  
  configure: ->
    return unless not @configured
    
    @buildHorses()
    wildHorses = (t for t in @world.thangs when t.type is "wild-horse" and t.exists and t.isAttackable)
    for horse in wildHorses
      horse.moveDelay = 0
    
    @configured = true
  
  decrementTimers: ->
    for name, timer of @timers
      @timers[name] -= @world.dt
    
    wildHorses = (t for t in @world.thangs when t.type is "wild-horse" and t.exists and t.isAttackable)
    for horse in wildHorses
      horse.moveDelay -= @world.dt
  
  findRandomPos: (unit) ->
    #
    # findRandomPos
    #   | finds a random position and returns it
    #
    r = Math.round(@world.rand.randf2(1, 10))
    if r is 1 or not unit.currentHeading
      unit.currentHeading = Math.random() * Math.PI * 2
    
    dx = 7 * Math.cos(unit.currentHeading)
    dy = 7 * Math.sin(unit.currentHeading)
    
    return {x: Math.round(unit.pos.x + dx), y: Math.round(unit.pos.y + dy)}
  
  horsesRoutine: ->
    #
    # horsesRoutine
    #   | all of the behavior related to the wild horses
    #
    @tagHorses()
    @followHorses()
    @checkHorseGoal()
    @roamHorses()
  
  buildHorses: ->
    #
    # buildHorses
    #   | build all of the horses
    #
    for i in [1..@numHorses] by 1
      pos = @pickPointFromRegions([@rectangles["horse-spawn"]])
      @instabuild("wild-horse", pos.x, pos.y)
  
  tagHorses: ->
    #
    # tagHorses
    #   | finds the closest horse to the hero after he says 'whoa' and if it's close enough tag it
    #
    if @tagHorse and @horseFollowing
      @tagHorse = false
    else if @tagHorse and not @horseFollowing
      closestHorse = false
      wildHorses = (t for t in @world.thangs when t.type is "wild-horse" and t.exists and t.isAttackable)
      for horse in wildHorses
        horse.distance = @hero.distanceTo(horse)
        if not closestHorse
          closestHorse = horse
        else if horse.distance < closestHorse.distance
          closestHorse = horse
      if closestHorse.distance <= 15
        closestHorse.tagged = true
        @tagHorse = false
    
  followHorses: ->
    #
    # followHorses
    #   | looks for horses that are tagged and sets them to follow the hero
    #
    if not @tagHorse
      wildHorses = (t for t in @world.thangs when t.type is "wild-horse" and t.exists and t.isAttackable)
      for horse in wildHorses
        if horse.tagged
          horse.following = true
          horse.tagged = false
          horse.maxSpeed = 20
          horse.addTrackedProperties ['maxSpeed', 'number']
          horse.keepTrackedProperty 'maxSpeed'
          @horseFollowing = true
  
  roamHorses: ->
    #
    # roamHorses
    #   | the horses randomly roam around the level
    #
    wildHorses = (t for t in @world.thangs when t.type is "wild-horse" and t.exists and t.isAttackable)
    for horse in wildHorses
      if not horse.following and horse.moveDelay <= 0
        pos = @findRandomPos(horse)
        while not @isPathClear(horse.pos, pos) or (pos.x < 40 and pos.y > 43)
          pos = @findRandomPos(horse)
        if (pos)
          horse.moveDelay = @world.rand.randf2(0, 1.5)
          horse.move pos
      else if horse.following
        horse.move Vector.subtract(horse.pos, @hero.pos).normalize().multiply(4).add(@hero.pos)
  
  checkHorseGoal: ->
    #
    # checkHorseGoal
    #   | watches for the hero standing on the red x if a horse is following and near the hero return him to the farm
    #
    if @rectangles['horse-finish'].containsPoint(@hero.pos)
      wildHorses = (t for t in @world.thangs when t.type is "wild-horse" and t.exists and t.isAttackable)
      for horse in wildHorses
        if horse.following and @hero.distanceTo(horse) <= 15
          @horseFollowing = false
          horse.following = false
          horse.isAttackable = false
          horse.move @pickPointFromRegions([@rectangles["horse-farm"]])
  
  checkVictory: ->
    #
    # checkVictory
    #   | if there are no attackable horses left (all have been returned to the farm) the player wins
    #
    wildHorses = (t for t in @world.thangs when t.type is "wild-horse" and t.exists and t.isAttackable)
    if wildHorses.length <= 0
      @setGoalState 'capture-horses', 'success'
  
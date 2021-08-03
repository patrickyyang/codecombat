Component = require 'lib/world/component'

module.exports = class TreasureCaveReferee extends Component
  @className: 'TreasureCaveReferee'
  
  chooseAction: ->
    @decrementTimers()
    @checkVictory()
    
    if not @triggers.ogreDead and @ogre.health <= 0
      console.log('Ogre dead, spawning Coins')
      @triggers.ogreDead = true
      @spawnCoinsFromOgre()
      @yeti.move(@positions.yetiHome)
      console.log('Spawned coins')
      
    if not @yeti.dead and @yeti.canSee(@hero)
      @yeti.attack @hero
    if @yeti.dead and not @triggers.yetiAway
      @triggers.yetiAway = true

    if @checkFireTrap('distraction') and not @triggers.distraction
      @triggers.distraction = true
      @distractionMark.setExists(false)
      @distractionMark = undefined
      @timers.bombTimer = 5
      @hideMark = @instabuildMark(@positions.hide)
      @caveMark = @instabuildMark(@positions.cave)
    if @rectangles['hide'].containsPoint(@hero.pos) and @hideMark and @triggers.distraction
      @hideMark.setExists(false)
      @hideMark = undefined
    if @timers.bombTimer and @timers.bombTimer <= 0
      @timers.bombTimer = undefined
      @triggers.yetiAway = true  
      @explodeFireTraps()
      @timers.distractedTimer = 30
      if not @yeti.dead
        @yeti.say? 'Huh?'
        @yeti.move(@positions.distraction)
    if @timers.distractedTimer and @timers.distractedTimer <= 0
      @timers.distractedTimer = undefined
      if not @yeti.dead
        @yeti.say? 'Hmpf'
        @yeti.move(@positions.yetiHome)
    if not @triggers.goldCollected and @hero.gold >= @goldGoal and not (t for t in @built when t.value and t.exists).length and @world.age > 1
      @triggers.goldCollected = true
      if @caveMark
        @caveMark.setExists(false)
      @caveMark = undefined
      @campMark = @instabuildMark(@positions.camp)
  
  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    @yeti = @world.getThangByID 'Yeti'
    @ogre = @world.getThangByID 'Ogre'
  
    # Make Humans unattackable so they don't accidentally trigger the Yeti
    ally = @world.getThangByID 'Natalie'
    ally.isAttackable = false
    ally = @world.getThangByID 'Harold'
    ally.isAttackable = false
    ally = @world.getThangByID 'Douglas'
    ally.isAttackable = false
  
    @triggers = 
      'ogreDead'      : false
      'distraction'   : false
      'yetiAway'      : false
      'goldCollected' : false
      'escaped'       : false
  
    @positions = 
      'distraction' : {x: 64, y: 44}
      'hide'        : {x: 44, y: 8}
      'cave'        : {x: 16, y: 32}
      'camp'        : {x: 68, y: 12}
      'yetiHome'    : {x: 28, y: 28}
	
    @distractionMark = @instabuildMark(@positions.distraction)
  
    @goldGoal = 20 #currently coinspawn is hardcoded. see below
    
    @timers = 
      'deerTimer' : 1
    
    console.log('Set up complete')
  
  decrementTimers: ->
    for name, timer of @timers
      @timers[name] -= @world.dt
  
  instabuildMark: (pos) ->
    return @instabuild('x-mark-white', pos.x, pos.y)
  
  checkFireTrap: ->
    #
    # checkFireTrap
    #   | checks if a firetrap is in the distraction region, make it a dud so it doesn't explode until the end
    #
    firetraps = (t for t in @world.thangs when t.type is 'fire-trap' and t.exists and not t.exploded)
    for trap in firetraps
      if @rectangles['distraction'].containsPoint trap.pos
        trap.dud = true
        return true
    return false
  
  explodeFireTraps: ->
    #
    # explodeFireTraps
    #   | explode the firetrap so the Yeti gets distracted
    #
    firetraps = (t for t in @world.thangs when t.type is 'fire-trap' and t.exists and not t.exploded)
    for trap in firetraps
      trap.blastRadius = 20
      trap.dud = false
      trap.explode()
  
  spawnCoinsFromOgre: ->
    x = @ogre.pos.x
    y = @ogre.pos.y
    @instabuild('gem', x + @world.rand.randf2(-4, 4), y + @world.rand.randf2(-4, 4))
    @instabuild('gold-coin', x + @world.rand.randf2(-4, 4), y + @world.rand.randf2(-4, 4))
    @instabuild('gold-coin', x + @world.rand.randf2(-4, 4), y + @world.rand.randf2(-4, 4))
    @instabuild('gold-coin', x + @world.rand.randf2(-4, 4), y + @world.rand.randf2(-4, 4))
    @instabuild('silver-coin', x + @world.rand.randf2(-4, 4), y + @world.rand.randf2(-4, 4))
    @instabuild('silver-coin', x + @world.rand.randf2(-4, 4), y + @world.rand.randf2(-4, 4))
    @instabuild('bronze-coin', x + @world.rand.randf2(-4, 4), y + @world.rand.randf2(-4, 4))
    @instabuild('bronze-coin', x + @world.rand.randf2(-4, 4), y + @world.rand.randf2(-4, 4))
  
  checkVictory: ->
    if @hero.health <= 0
      @setGoalState 'escape', 'failure'
    else 
      if @triggers.goldCollected and @rectangles['camp'].containsPoint @hero.pos
        @setGoalState 'escape', 'success'
      if @triggers.goldCollected
        @setGoalState 'treasure', 'success'
      if @triggers.yetiAway or @yeti.dead
        @setGoalState 'distract', 'success'
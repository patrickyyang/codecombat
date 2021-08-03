Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class StormingTheTowerOfArethReferee extends Component
  @className: 'StormingTheTowerOfArethReferee'
  chooseAction: ->
    @nerfUnits()
    @decrementTimers()
    @checkVictory()
    @fireCannon()
    
    if @checkFireTrap('distraction', false) and not @triggers.distraction
      @triggers.distraction = true
      @distractionX.setExists(false)
      @distractionX = undefined
      @timers.distractionTimer = 1 
    else if @rectangles['distraction-retreat'].containsPoint(@hero.pos) and @distractionRetreatX and @triggers.distraction
      @distractionRetreatX.setExists(false)
      @distractionRetreatX = undefined
    else if @timers.distractionTimer and @timers.distractionTimer <= 0
      @actors.mudwich.say? "Ohhh! Shiny!"
      @actors.mudwich.move({x: 94, y: 19})
      @timers.distractionTimer = undefined
    else if @actors.mudwich.health <= 0 and not @triggers['mudwich-dead']
      @actors.cannon.attackRange = 0
      @timers.stormTroopsTimer = 1
      @triggers['mudwich-dead'] = true
    else if @timers.stormTroopsTimer and @timers.stormTroopsTimer <= 0
      @actors.captain.say "The cannon is disabled, CHARGE!!!"
      @sendOgres()
      @restoreUnits()
      @tents1X = @instabuild('x-mark-red', 60, 62)
      @tents2X = @instabuild('x-mark-red', 90, 53)
      @timers.stormTroopsTimer = undefined
    else if @checkFireTrap('tents1', true) and @checkFireTrap('tents2', true) and not @triggers.sabotage
      @triggers.sabotage = true
    else if @retreat and not @triggers['retreat-called']
      @timers.bombTimer = 6
      @actors.captain.say? "Fall back troops!"
      @nerfOgres()
      @retreatHumans()
      @instabuild('x-mark-wood', -16, 39)
      @instabuild('x-mark-wood', 11, 28)
      @triggers['retreat-called'] = true
    else if @timers.bombTimer and @timers.bombTimer <= 0
      @explodeFireTraps()
      @retreatOgres()
      @timers.bombTimer = undefined
      @triggers['complete'] = true
  
  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    
    @actors =
      "captain": @world.getThangByID 'Captain Morgan'
      "warlord": @world.getThangByID 'Ogre Warlord'
      "cannon": @world.getThangByID 'Cannon'
      "tower1": @world.getThangByID 'Tower of Areth'
      "tower2": @world.getThangByID 'Tower of Areth II'
      "mudwich": @world.getThangByID 'Mudwich'
    
    @actors.cannon.isAttackable = @actors.tower1.isAttackable = @actors.tower2.isAttackable = false
    
    @triggers =
      'distraction': false
      'mudwich-dead': false
      'sabotage': false
      'retreat-called': false
      'complete': false
    
    @timers =
      "cannonTimer": 2
    
    @cannonCoords = [
      {x: 27, y: 31}
      {x: 32, y: 34}
    ]
    
    @distractionX = @instabuild('x-mark-red', 94, 19)
    @distractionRetreatX = @instabuild('x-mark-wood', 79, 6)
    
    @unitsRestored = false
    @nerfUnits()
  
  decrementTimers: ->
    for name, timer of @timers
      @timers[name] -= @world.dt
  
  sendOgres: ->
    #
    # sendOgres
    #   | send all of the ogres to attack the captain
    #
    units = (t for t in @world.getSystem("Combat").attackables when t.isAttackable and t.team is "ogres" and t isnt @hero and t isnt @actors.mudwich and t.attack?)
    for unit in units
      unit.attack @actors.captain
  
  retreatHumans: ->
    #
    # retreatHumans
    #   | make the human army retreat back to the rallypoint
    #
    units = (t for t in @world.getSystem("Combat").attackables when t.isAttackable and t.team is "humans" and t isnt @hero and t isnt @actors.mudwich and t.move?)
    for unit in units
      unit.move({x: -12, y: 38})
  
  retreatOgres: ->
    #
    # retreatOgres
    #   | retreat ogres back to vilage after their supplies have been destroyed
    #
    @actors.warlord.say? "NOOOO! Our supplies!"
    units = (t for t in @world.getSystem("Combat").attackables when t.isAttackable and t.team is "ogres" and t isnt @hero and t isnt @actors.mudwich and t.move?)
    for unit in units
      unit.move({x: 69, y: 54})
  
  nerfUnits: ->
    #
    # nerfUnits
    #   | nerf units so they don't auto attack each other at start of the level
    #
    if not @unitsRestored
      units = (t for t in @world.getSystem("Combat").attackables when t.isAttackable and t isnt @hero and t isnt @actors.mudwich and t.setTarget?)
      for unit in units
        unit.visualRange = 5
        unit.visualRangeSquared = unit.visualRange * unit.visualRange
        unit.setTarget(null)
        unit.setAction("idle")
  
  nerfOgres: ->
    #
    # nerfOgres
    #   | nerf ogres so they stand there confused as the humans retreat
    #
    enemies = (t for t in @world.getSystem("Combat").attackables when t.isAttackable and t.team is "ogres" and t isnt @hero and t isnt @actors.mudwich and t.setTarget?)
    for unit in enemies
      unit.say? "???"
      unit.visualRange = 0
      unit.visualRangeSquared = unit.visualRange * unit.visualRange
      unit.setTarget(null)
      unit.setAction("idle")
  
  restoreUnits: ->
    #
    # restoreUnits
    #   | restore the units so they will go attack each other after the cannon is disabled
    #
    enemies = (t for t in @world.getSystem("Combat").attackables when t.isAttackable and t isnt @hero and t isnt @actors.mudwich and t.visualRange)
    for unit in enemies
      unit.visualRange = 90
      unit.visualRangeSquared = unit.visualRange * unit.visualRange
      if unit.healthReplenishRate < 30
        unit.healthReplenishRate = 150
    @unitsRestored = true
  
  fireCannon: ->
    #
    # fireCannon
    #   | fires the cannon
    #
    if @timers.cannonTimer <= 0
      if @actors.cannon.exists and @actors.cannon.attackRange > 0
        r = Math.round(@world.rand.randf2(0, @cannonCoords.length - 1))
        @actors.cannon.attackXY @cannonCoords[r].x, @cannonCoords[r].y
        @timers.cannonTimer = 2
  
  explodeFireTraps: ->
    #
    # explodeFireTraps
    #   | explode the supplies in the camp and send barrels flying
    #
    firetraps = (t for t in @world.thangs when t.type is 'fire-trap' and t.exists and not t.exploded)
    for trap in firetraps
      trap.blastRadius = 20
      trap.dud = false
      trap.explode()
    
    barrels = (t for t in @world.thangs when t.spriteName is 'Barrel' and t.exists)
    for barrel in barrels when barrel.velocity
      for trap in firetraps
        v = Vector.subtract barrel.pos, trap.pos, true
        v.z += trap.depth / 2 - 25
        d = v.magnitude(false)
        continue unless d < 20
        blastRatio = (20 - d) / 20
        momentum = v.copy().normalize(true).multiply blastRatio * 13000, true
        barrel.velocity.add Vector.divide(momentum, barrel.mass, true), true
      barrel.cancelCollisions()
  
  checkFireTrap: (rectangle, makeDud) ->
    #
    # checkFireTrap
    #   | checks if a firetrap is in a rectangle region, make it a dud so it doesn't explode until the end
    #
    firetraps = (t for t in @world.thangs when t.type is 'fire-trap' and t.exists and not t.exploded)
    for trap in firetraps
      if @rectangles[String(rectangle)].containsPoint trap.pos
        if makeDud
          trap.dud = true
        return true
    return false
    
  checkVictory: ->
    if @hero.health <= 0
      @setGoalState 'escape', 'failure'
    else if @triggers.complete and @rectangles['rallypoint'].containsPoint @hero.pos
      @setGoalState 'escape', 'success'
    else if @triggers.sabotage
      @setGoalState 'sabotage', 'success'
    else if @triggers.distraction
      @setGoalState 'distract', 'success'
    else if @world.age >= 60
      if not @triggers.sabotage
        @setGoalState 'sabotage', 'failure'
Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{MAX_COOLDOWN} = require 'lib/world/systems/action'

module.exports = class Mine extends Component
  @className: "Mine"
  isHazard: true

  constructor: (config) ->
    super config

  attach: (thang) ->
    super thang
    thang.addActions name: 'die', cooldown: MAX_COOLDOWN
    Object.defineProperty(thang, 'triggered', {
      get: @getTriggered,
      set: (x) -> throw new Error("You can't set trap.triggered")
    })
    
  chooseAction: ->
    if @explodeTimer?
      @explodeTimer -= @world.dt
    if not @exploded and not @dud and @triggered
      @explode()
    else if @explodeTimer? and @explodeTimer <= 0 and not @exploded
      @explode()
  
  getTriggered: ->
    combat = @world.getSystem("Combat")
    justPlaced = not @initialTriggerersInRange?
    @initialTriggerersInRange ?= {}
    @spawnTime ?= @world.age
    for thang in combat.attackables
      continue if @team and not @friendlyFire and thang.team is @team
      d2 = @distanceSquared(thang)
      inTriggerRange = d2 < Math.pow(@attackRange, 2)
      inInitialTriggerRange = d2 < Math.pow(@attackRange * 2, 2)
      if (thang.isGrounded() or thang.pos.z + (thang.velocity?.z ? 0) * @world.dt <= thang.depth / 2) and inInitialTriggerRange
        if justPlaced
          @initialTriggerersInRange[thang.id] = thang
        else if inTriggerRange and (@world.age - @spawnTime) > 2 and not (@ in (thang.built ? []))
          # Blow up after 2 seconds even if the Thang was standing on it when you built it, except if it's you.
          return true
        else if inTriggerRange and not @initialTriggerersInRange[thang.id]
          return true
      else if @initialTriggerersInRange[thang.id] 
        @initialTriggerersInRange[thang.id] = false
    return false
  
  explode: ->
    combat = @world.getSystem("Combat")
    
    for thang in combat.attackables.concat(combat.corpses)
      continue if @team and not @friendlyFire and thang.team is @team
      v = Vector.subtract thang.pos, @pos, true
      v.z += @depth / 2
      d = v.magnitude(false)
      continue unless d < @blastRadius
      blastRatio = Math.min 1, (@blastRadius - d + @attackRange) / @blastRadius
      momentum = v.copy().normalize(true).multiply blastRatio * @mass, true  # Could also add explosion momentum multiplier
      if thang.maintainsElevation?()
        momentum.z = 0
      @performAttack thang, blastRatio, momentum
      #console.log @id, "doing", blastRatio * @attackDamage, "to", thang.id, "with d", d, "of", @blastRadius, "and momentum", momentum, "from vz", v.z, "thang.pos", thang.pos

    @addCurrentEvent 'hit'
    @velocity.multiply 0
    @exploded = true
    @lifespan = 1 if @lifespan?
    
    if @chainReacts
      for trap in @getFireTraps()
          trap.explodeTimer = 0.25 * @distance(trap) / @blastRadius
    
    @setAction 'die'  # TODO: some sort of explode action might make more sense? 'die' being for combat system and all
    @act()
  
  getFireTraps: ->
    _.filter @world.thangs, (thang) => thang.type is 'fire-trap' and thang isnt @ and @distanceSquared(thang) <= @blastRadius * @blastRadius and not thang.exploded and not thang.explodeTimer
  
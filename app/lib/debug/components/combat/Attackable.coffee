Component = require 'lib/world/component'

MAX_COOLDOWN = require 'lib/world/systems/action'
Vector = require 'lib/world/vector'

module.exports = class Attackable extends Component
  @className: 'Attackable'
  isAttackable: true
  damageMitigationFactor: 1

  constructor: (config) ->
    super config
    @health = @maxHealth

  attach: (thang) ->
    super thang
    thang.addTrackedProperties ["health", "number"], ["healthReplenishRate", "number"], ["maxHealth", "number"]
    thang.addActions name: 'die', cooldown: MAX_COOLDOWN

  initialize: ->
    Object.defineProperty(@, 'esper_maxHealth', {
      enumerable: true,
      get: () -> @maxHealth,
      set: (x) ->
        return if x is undefined
        unless _.isNumber(x) and x > 0
          throw new Error "maxHealth must be a number greater than zero."
        
        if @health is @maxHealth
          @health = x if @health is @maxHealth
          @keepTrackedProperty 'health'
        @maxHealth = x
        @keepTrackedProperty 'maxHealth'
    })

  takeDamage: (damage, attacker, momentum=null) ->
    damage *= @damageMitigationFactor
    
    unless @dead 
      @world.getSystem('Combat').addDamage attacker?.team, @team, damage 
    
    @health -= damage
    @keepTrackedProperty 'health'
    #console.log @id, "took", damage, "damage and is at", @health, "on frame", @world.frames.length
    unless @dead
      @addCurrentEvent? 'take-damage'
      if @health <= 0
        @killer = attacker
        if @velocity
          @rotation = (@velocity.heading() + Math.PI) % (2 * Math.PI)
          @hasRotated = true
    if @velocity? and momentum?
      @velocity.z = Math.max(@velocity.z, 0) if momentum.z > 1 and @isGrounded?()
      @velocity.add Vector.divide(momentum, @mass, true), true
      #console.log @id, "got momentum", momentum.toString(true), "with new v", @velocity, "from", attacker if attacker.id is 'Anya'
    if @damageReflection and attacker?.takeDamage and @distance(attacker, true) < (@damageReflectionRange or 5) and not @reflectingDamageNow
      @reflectingDamageNow = true
      attacker.takeDamage @damageReflection, @
      @reflectingDamageNow = false

  die: ->
    @setAction 'die'
    @act true
    @cancelCollisions?(true)
    event = killer: @killer
    event.killerHealth = @killer.health if @killer?.health?
    event.maxHealth = @maxHealth
    @publishNote "thang-died", event
    @world.getSystem('Combat').addDefeated @killer?.team, @team
    @addCurrentEvent? 'die'
    @dead = true
    @health = Math.min(0, @health)
    @isAttackable = false
    @trigger? "defeat", event
    @updateRegistration()
  
  revive: ->
    @setAction 'idle'
    @actionHeats.all = 0
    @restoreCollisions?()
    @dead = false
    @isAttackable = true
    @updateRegistration()

  update: ->
    if @health > 0 and @healthReplenishRate and (@health < @maxHealth or @healthReplenishRate < 0)
      @keepTrackedProperty 'health'
      @health = Math.min @maxHealth, @health + @healthReplenishRate * @world.dt
    if @health > @maxHealth
      @health = @maxHealth

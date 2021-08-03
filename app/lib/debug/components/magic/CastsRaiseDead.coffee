Component = require 'lib/world/component'

module.exports = class CastsRaiseDead extends Component
  @className: 'CastsRaiseDead'

  constructor: (config) ->
    super config
    @_raiseDeadSpell = name: 'raise-dead', cooldown: @cooldown, specificCooldown: @specificCooldown, radius: @radius, duration: @duration, power: @power
    delete @radius
    delete @duration
    delete @cooldown
    delete @specificCooldown
    delete @power

  attach: (thang) ->
    super thang
    thang.addSpell @_raiseDeadSpell
    
  castRaiseDead: ->
    @cast 'raise-dead', @
    
  'getTarget_raise-dead': ->
    corpses = _.filter @world.getSystem('Combat').corpses, (corpse) => corpse.hasEffects and @distance(corpse) < @spells['raise-dead'].radius
    if corpses.length > 1
      return @
    return null

  'perform_raise-dead': ->
    corpses = _.filter @world.getSystem('Combat').corpses, (corpse) => corpse.hasEffects and @distance(corpse) < @spells['raise-dead'].radius
    if corpses.length > 1
      corpses = @world.rand.shuffle(corpses)  
    bodies = []
    body = 0
    power = 0
    while bodies.length < corpses.length and power < @spells['raise-dead'].power 
      corpse = corpses[body]
      type = _.string.slugify(corpse.spriteName)
      power += @world.getSystem('Existence').buildTypePower[type] or 25
      bodies.push(corpse)
      ++body

    for corpse in bodies
      do (corpse) => 
        if corpse
          corpse.originalDie = corpse.die
          effects = [
            {name: 'undead', duration: @spells['raise-dead'].duration - @world.dt, reverts: true, factor: 1.1, targetProperty: 'scaleFactor', onRevert: -> corpse.die()}
            {name: 'undead', duration: @spells['raise-dead'].duration, reverts: true, setTo: false, targetProperty: 'dead'}
            {name: 'undead', duration: @spells['raise-dead'].duration, reverts: true, setTo: @raisedChooseAction, targetProperty: 'chooseAction'}
            {name: 'undead', duration: @spells['raise-dead'].duration, reverts: true, setTo: @raisedDie, targetProperty: 'die'}
            {name: 'undead', duration: @spells['raise-dead'].duration, reverts: true, setTo: corpse.maxHealth / 2, targetProperty: 'health'}
            {name: 'undead', duration: @spells['raise-dead'].duration, reverts: true, factor: 0.5, targetProperty: 'maxSpeed'}
            {name: 'undead', duration: @spells['raise-dead'].duration, reverts: true, setTo: @team, targetProperty: 'team'}
            {name: 'undead', duration: @spells['raise-dead'].duration, reverts: true, setTo: @superteam, targetProperty: 'superteam'}
          ]
          corpse.addEffect effect, @ for effect in effects
          corpse.revive()
          corpse.setAction 'idle'
          corpse.setTarget null
    args = [parseFloat(@pos.x.toFixed(2)), parseFloat(@pos.y.toFixed(2)), parseFloat(@spells['raise-dead'].radius.toFixed(2)), '#000000']
    @addCurrentEvent "aoe-#{JSON.stringify(args)}"

  raisedChooseAction: ->
    # This is what the enemy unit does while raised.
    return unless @health > 0
    return unless @canSee and @getNearest and @distance
    @sayWithoutBlocking? 'Oooo'
    enemies = (t for t in @world.getSystem('Combat').attackables when t.exists and t.team isnt @team and not t.dead and @canSee(t))
    nearestCombatant = @getNearest(enemies)
    if nearestCombatant
      if @attack and @distance(nearestCombatant) < @attackRange
        @attack nearestCombatant
      else if @move
        @move nearestCombatant.pos

  raisedDie: ->
    # What happens when the unit dies again.
    return if @dead
    @dead = true

    # This will make all the effects (with a duration) finish and revert.
    effect.timeSinceStart = 9001 for effect in @effects when effect.name is 'undead'
    @updateEffects()
    
    # Make sure really-dead corpses don't keep going.
    @setTarget null
    @setAction 'idle'
    
    @originalDie()

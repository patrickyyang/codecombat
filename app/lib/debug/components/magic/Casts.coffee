Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Casts extends Component
  @className: 'Casts'
  
  ###
  @spellSchema =
    type: 'object'
    required: ['name', 'cooldown']
    properties:
      name:
        type: 'string'
        description: 'The handle for the spell like "arctic-blast" which we key the method off as well, so "perform_arctic-blast" would apply damage, effects, etc.'
      range:
        type: 'number'
        description: 'Distance in meters this spell can be cast from.'
      cooldown:
        type: 'number'
        description: 'Same as an action'
      specificCooldown:
        type: 'number'
        description: 'Same as an action'
  ###
  
  attach: (thang) ->
    super(thang)
    thang.spellHeats = {}
    thang.spellNames = []
    thang.addActions name: 'cast', cooldown: 1

  addSpell: (spell) ->
    @spells ?= {}
    @spells[spell.name] = spell
    @spellNames.push spell.name

  setSpell: (spell, methodName='setSpell') ->
    spell = @getSpellFromName spell, methodName
    if spell isnt @spell
      @keepTrackedProperty 'spell'
      @spell = spell
  
  cast: (spell, target, castArguments...) ->
    target ?= @ if spell in ['time-warp', 'raise-dead', 'windstorm', 'goldstorm', 'summon-undead', 'summon-burl', 'summon-fangrider']  # TODO: figure out how to not have to hard-code the self target list check in here.
    unless target
      throw new ArgumentError "You need something to cast upon.", 'cast', "target", "object", target
    if _.isString target
      target = @world.getThangByID target
    else if target and not target.isThang and _.isString(target.id) and targetThang = @world.getThangByID target.id
      # Temporary workaround for Python API protection bug that makes them not Thangs
      target = targetThang
    @castArguments = castArguments
    
    setTargetFn = @setTarget
    if spell in ['teleport', 'antigravity', 'ice-rink', 'windstorm']
      target = targetPos if targetPos = target?.pos
      setTargetFn = @setTargetPos
    else if spell in ['fireball', 'poison-cloud', 'raise-dead', 'shockwave'] and target?.x and target?.y
      setTargetFn = @setTargetPos
    unless @canCast spell, target, false, false
      @sayWithoutBlocking? "I can't cast \"#{spell}\" on the target"
      return @unblock?()
    @setSpell spell, 'cast'
    
    setTargetFn.call @, target, 'cast'
    
    @announceAction? "cast \"#{spell}\""
    
    @intent = 'cast'
    if not @actions.move or not @spell.range or @distance(target) <= @spell.range
      @setAction 'cast'
      @updateRegistration()
    else
      @currentSpeedRatio = 1
      @setAction "move"
      
    return @block?() unless @commander?

  getSpellFromName: (spell, methodName) ->
    if typeof spell is 'undefined'
      throw new ArgumentError "You need a spell to cast.", methodName, "spell", "string", spell
    unless _.isString spell
      throw new ArgumentError "You need a string spell; one of [#{_.keys(@spells).join(', ')}]", methodName, "spell", "string", spell
    unless spell of @spells
      [closestScore, message] = [0, '']
      for otherSpell of @spells
        matchScore = otherSpell.score spell, 0.8
        [closestScore, message] = [matchScore, "The spell is \"#{otherSpell}\", not \"#{spell}\"."] if matchScore > closestScore
      if closestScore >= 0.5
        throw new ArgumentError message, methodName, "spell", "string", spell
      return null if methodName is 'canCast'
      throw new ArgumentError "You don't have spell \"#{spell}\", only [#{_.keys(@spells).join(', ')}]", methodName, "spell", "string", spell
    @spells[spell]
  
  canCast: (spell, target, checkCooldown=true, checkDoubleEffect=true) ->
    spell = @getSpellFromName spell, 'canCast'
    return false unless spell  # http://discourse.codecombat.com/t/cleave-x-powerup-and-isready-function/2427/4
    return false if checkCooldown and @spellHeats[spell.name]
    if not target
      # Just let them do canCast('spell-name') with no target.
      return true
    if _.isString target
      target = @world.getThangByID target
    if target and not target.isThang and _.isString(target.id) and targetThang = @world.getThangByID target.id
      # Temporary workaround for Python API protection bug that makes them not Thangs
      target = targetThang
      
    if spell.name in ['teleport', 'antigravity', 'ice-rink', 'windstorm', 'fireball', 'poison-cloud', 'raise-dead', 'shockwave']
      targetPos = if target?.pos then target.pos else target
      unless _.isNumber targetPos?.x + targetPos?.y
        throw new ArgumentError "Target must be an {x, y} coordinate.", "canCast", "targetPos", "object", targetPos
      #console.log @world.age, @id, 'canCast', spell.name
      return true
      
    unless target?.isThang
      throw new ArgumentError "Target must be a unit.", "canCast", "target", "unit", target
    # TODO: this is given that spells only cause effects. Need a better system for specifying if a spell would have *any* effect on the target
    return false unless target.hasEffects
    return false if checkDoubleEffect and _.find target.effects, name: spell.name unless spell.name in ['heal', 'sacrifice']
    return true
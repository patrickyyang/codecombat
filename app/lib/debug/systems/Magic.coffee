System = require 'lib/world/system'

module.exports = class Magic extends System
  constructor: (world, config) ->
    super world, config
    @casters = @addRegistry (thang) -> thang.cast and thang.exists and thang.acts

  update: ->
    hash = 0
    casters = @casters.slice()  # avoid changing during iteration
    for caster in casters
      #dt = @world.dt * (caster.actionTimeFactor or 1)
      dt = @world.dt  # Don't let actionTimeFactor (like from slow/haste) affect spell cooldowns.
      for spellName, heat of caster.spellHeats
        caster.spellHeats[spellName] = Math.max 0, heat - dt
      target = caster.target or caster.targetPos
      
      continue unless caster.intent is 'cast'
      if not caster.actions.move or not caster.spell.range or (caster.target? and caster.distance(target) <= caster.spell.range)
        caster.setAction 'cast'
        caster.updateRegistration()
      continue unless target and caster.action is 'cast' and caster.canCast(caster.spell.name, target)
      caster.actions.cast.cooldown = caster.spell.cooldown
      if caster.act()
        methodName = "perform_#{caster.spell.name}"
        caster[methodName]()
        caster.castOnce = true if caster.castOnceTarget  #if caster.castOnceTarget?.id is target?.id  # what is the target matching for?
        caster.spellHeats[caster.spell.name] = caster.spell.specificCooldown ? caster.spell.cooldown
        if caster.commander and caster.castingCommandedSpellTarget
          # Stop casting the spell (like, if we have ordered a minion to cast, so that she doesn't just keep casting)
          caster.hasCastCommandedSpell = true
        hash += @world.age * @hashString(caster.id + caster.spell.name)
        caster.setTarget null
        caster.setAction 'idle'
        caster.intent = undefined
        caster.unblock?()
    return hash

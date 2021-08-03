Component = require 'lib/world/component'

module.exports = class CastsDrainLife extends Component
  @className: 'CastsDrainLife'

  constructor: (config) ->
    super config
    @_drainLifeSpell = name: 'drain-life', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, damage: @damage
    delete @cooldown
    delete @specificCooldown
    delete @range
    delete @damage

  attach: (thang) ->
    super thang
    thang.addSpell @_drainLifeSpell
    
  'perform_drain-life': ->
    #@target.effects = (e for e in @target.effects when e.name isnt 'drain-life')
    duration = @spells['drain-life'].cooldown
    damagePerFrame = @spells['drain-life'].damage / duration / @world.frameRate
    targetEffects = [
      {name: 'drain-life', duration: duration, reverts: false, addend: -damagePerFrame, targetProperty: 'health', repeatsEvery: @world.dt}
    ]
    @target.addEffect effect for effect in targetEffects
    
    #@effects = (e for e in @effects when e.name isnt 'drain-life')
    myEffects = [
      {name: 'drain-life', duration: duration, reverts: false, addend: damagePerFrame, targetProperty: 'health', repeatsEvery: @world.dt}
    ]
    @addEffect effect for effect in myEffects
    @unhide?() if @hidden

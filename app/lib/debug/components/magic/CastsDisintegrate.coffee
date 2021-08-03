Component = require 'lib/world/component'

module.exports = class CastsDisintegrate extends Component
  @className: 'CastsDisintegrate'

  constructor: (config) ->
    super config
    @_disintegrateSpell = name: 'disintegrate', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, damage: @damage
    delete @damage
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_disintegrateSpell
    
  perform_disintegrate: ->
    @target.effects = (e for e in @target.effects when e.name isnt 'disintegrate')
    damagePerFrame = @spells.disintegrate.damage * @world.dt
    effects = [
      {name: 'disintegrate', duration: 1, addend: -damagePerFrame, targetProperty: 'health', repeatsEvery: @world.dt}
    ]
    @target.addEffect effect, @ for effect in effects
    @unhide?() if @hidden

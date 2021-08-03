Component = require 'lib/world/component'

module.exports = class CastsEarthskin extends Component
  @className: 'CastsEarthskin'

  constructor: (config) ->
    super config
    @_earthskinSpell = name: 'earthskin', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, duration: @duration, factor: @factor
    delete @cooldown
    delete @specificCooldown
    delete @range
    delete @duration
    delete @factor

  attach: (thang) ->
    super thang
    thang.addSpell @_earthskinSpell
    
  perform_earthskin: ->
    @target.effects = (e for e in @target.effects when e.name isnt 'earthskin')
    effects = [
      {name: 'earthskin', duration: @spells.earthskin.duration, reverts: true, factor: @spells.earthskin.factor, targetProperty: 'maxHealth'}
      {name: 'earthskin', duration: @spells.earthskin.duration, revertsProportionally: true, factor: @spells.earthskin.factor, targetProperty: 'health'}
    ]
    @target.addEffect effect, @ for effect in effects
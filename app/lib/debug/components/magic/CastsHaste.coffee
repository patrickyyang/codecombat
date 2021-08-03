Component = require 'lib/world/component'

module.exports = class CastsHaste extends Component
  @className: 'CastsHaste'
  
  constructor: (config) ->
    super config
    @_hasteSpell = name: 'haste', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, duration: @duration, factor: @factor
    delete @duration
    delete @factor
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_hasteSpell
    
  castHaste: (target) ->
    @cast 'haste', target

  perform_haste: ->
    @target.effects = (e for e in @target.effects when e.name isnt 'haste')
    effects = [
      {name: 'haste', duration: @spells.haste.duration, reverts: true, factor: @spells.haste.factor, targetProperty: 'maxSpeed'}
      {name: 'haste', duration: @spells.haste.duration, reverts: true, factor: @spells.haste.factor, targetProperty: 'actionTimeFactor'}
    ]
    @target.addEffect effect, @ for effect in effects


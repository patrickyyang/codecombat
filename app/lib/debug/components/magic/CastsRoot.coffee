Component = require 'lib/world/component'

module.exports = class CastsRoot extends Component
  @className: 'CastsRoot'

  constructor: (config) ->
    super config
    @_rootSpell = name: 'root', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, duration: @duration, factor: @factor
    delete @duration
    delete @factor
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_rootSpell
    
  perform_root: ->
    @target.effects = (e for e in @target.effects when e.name isnt 'root')
    @target.velocity?.multiply @spells.root.factor
    effects = [
      {name: 'root', duration: @spells.root.duration, reverts: true, factor: @spells.root.factor, targetProperty: 'maxSpeed'}
    ]
    @target.addEffect effect, @ for effect in effects
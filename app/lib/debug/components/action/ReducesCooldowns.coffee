Component = require 'lib/world/component'

module.exports = class ReducesCooldowns extends Component
  @className: 'ReducesCooldowns'

  attach: (thang) ->
    reduceCooldownAction = name: 'reduceCooldown', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions reduceCooldownAction

  reduceCooldown: ->
    @setAction 'reduceCooldown'
    return @block()

  update: ->
    if @action is 'reduceCooldown' and @act()
      @unblock()
      reduceCooldownEffects = [
        {name: 'haste', duration: @reduceCooldownDuration, reverts: true, factor: @reduceCooldownFactor, targetProperty: 'actionTimeFactor'}
      ]
      @addEffect effect for effect in reduceCooldownEffects

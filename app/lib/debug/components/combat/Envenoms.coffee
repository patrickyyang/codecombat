Component = require 'lib/world/component'

module.exports = class Envenoms extends Component
  @className: 'Envenoms'

  attach: (thang) ->
    envenomAction = name: 'envenom', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions envenomAction

  envenom: ->
    @setAction 'envenom'
    return @block?()

  update: ->
    return unless @action is 'envenom' and @act()
    @unblock?()
    @envenomed = true

  performAttack: (target, damageRatio=1, momentum=null) ->
    return unless @envenomed
    @envenomed = false
    return unless target.hasEffects
    heroDPS = @attackDamage / @actions.attack.cooldown * (@attackDamageFactor ? 1)
    envenomDPS = heroDPS / 2
    damagePerFrame = envenomDPS * @world.dt
    target.addEffect name: 'poison', duration: @envenomDuration, targetProperty: 'health', repeatsEvery: @world.dt, addend: -damagePerFrame

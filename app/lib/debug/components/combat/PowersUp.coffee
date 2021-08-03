Component = require 'lib/world/component'

module.exports = class PowersUp extends Component
  @className: 'PowersUp'

  attach: (thang) ->
    powerUpAction = name: 'power-up', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions powerUpAction

  powerUp: ->
    @setAction 'power-up'
    if @getCooldown('power-up') > 1
      "done"
    else if @poweredUpOnce
      @poweredUpOnce = false
      @setAction 'idle'
      "done"
    else
      "power-up"
    
  update: ->
    return unless @action is 'power-up' and @act()
    @effects = (effect for effect in @effects when effect.name not in ['power-up', 'power-up-2'])
    @addEffect effect for effect in @powerUpEffects.slice()
    @poweredUpOnce = true if @plan
    @brake?()

  performAttack: ->
    if @powerUpEndsOnAttack
      effect.timeSinceStart += 9001 for effect in @effects when effect.timeSinceStart? and effect.name in ['power-up', 'power-up-2']

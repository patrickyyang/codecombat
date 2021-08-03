Component = require 'lib/world/component'

module.exports = class Hides extends Component
  @className: 'Hides'

  attach: (thang) ->
    hideAction = name: 'hide', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions hideAction
    thang.addTrackedProperties ['hidden', 'boolean']

  hide: ->
    @setAction 'hide'
    return @block()
    
  update: ->
    hidden = @hidden
    if @action is 'hide' and @act()
      @unblock()
      @unhide() if @hidden
      hideEffects = [
        {name: 'hide', duration: @hideDuration, reverts: true, factor: 0.5, targetProperty: 'alpha'}
        {name: 'hide', duration: @hideDuration, reverts: true, setTo: true, targetProperty: 'hidden'}
      ]
      @addEffect effect for effect in hideEffects
      hidden = true
    if hidden
      for targeter in @world.thangs when targeter.target is @ and targeter.exists and targeter isnt @
        targeter.setTarget null

  performAttack: ->
    @unhide() if @hidden
  
  unhide: ->
    # This will make all the 'hide' effects finish and revert.
    effect.timeSinceStart = 9001 for effect in @effects when effect.name is 'hide'
    @updateEffects 'hide'
    
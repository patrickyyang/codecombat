Component = require 'lib/world/component'

module.exports = class CastsInvisibility extends Component
  @className: 'CastsInvisibility'

  constructor: (config) ->
    super config
    @_invisibilitySpell = name: 'invisibility', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, duration: @duration
    delete @duration
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_invisibilitySpell
    
  perform_invisibility: ->
    @target.unhide?()  # Primary way to cancel any other hide effects
    @target.effects = (e for e in @target.effects when e.name isnt 'hide')  # Backup
    @target.unhiddenPerformAttack = @target.performAttack
    @target.unhide ?= @unhide
    effects = [
      {name: 'hide', duration: @spells.invisibility.duration, reverts: true, setTo: true, targetProperty: 'hidden'}
      {name: 'hide', duration: @spells.invisibility.duration, reverts: true, factor: 0.5, targetProperty: 'alpha'}
      {name: 'hide', duration: @spells.invisibility.duration, reverts: true, setTo: @hiddenPerformAttack, targetProperty: 'performAttack'}
      {name: 'hide', duration: @spells.invisibility.duration, reverts: false, setTo: @target.unhiddenPerformAttack, targetProperty: 'unhiddenPerformAttack'}
    ]
    @target.addEffect effect, @ for effect in effects
    for targeter in @world.thangs when targeter.target is @target and targeter.exists and targeter isnt @
      targeter.setTarget null

  hiddenPerformAttack: ->
    @unhide?() if @hidden
    @unhiddenPerformAttack arguments...
    
  unhide: ->
    # This will make all the 'hide' effects finish and revert.
    effect.timeSinceStart = 9001 for effect in @effects when effect.name is 'hide'
    @updateEffects 'hide'
    
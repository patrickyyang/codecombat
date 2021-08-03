Component = require 'lib/world/component'

module.exports = class PhaseShifts extends Component
  @className: 'PhaseShifts'
  
  constructor: (config) ->
    super config
    @wispsThangType = (@requiredThangTypes ? [])[0]
  
  attach: (thang) ->
    phaseShiftAction = name: 'phase-shift', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions phaseShiftAction
    #thang.addTrackedProperties ['hidden', 'boolean']
    thang.phaseShifted = false
    thang.addTrackedProperties ['phaseShifted', 'boolean']

  phaseShift: ->
    @setAction 'phase-shift'
    return @block()

  performPhaseShift: ->
    @unhide?()
    @unblock()
    @configureWisps() unless @wispsComponents
    @unhiddenPerformAttack = @performAttack
    phaseShiftEffects = [
        {name: 'hide', duration: @phaseShiftDuration, reverts: true, setTo: true, targetProperty: 'hidden'}
        {name: 'phase-shift', duration: @phaseShiftDuration, reverts: true, setTo: true, factor: 0, targetProperty: 'alpha'}
        {name: 'phase-shift', duration: @phaseShiftDuration, reverts: true, onRevert: @unphaseShift.bind(@), setTo: true, targetProperty: 'phaseShifted'}
        {name: 'phase-shift', duration: @phaseShiftDuration, reverts: true, factor: @phaseShiftFactor, targetProperty: 'maxSpeed'}
        {name: 'phase-shift', duration: @phaseShiftDuration, reverts: true, setTo: false, targetProperty: 'isAttackable'}
        {name: 'phase-shift', duration: @phaseShiftDuration, reverts: true, setTo: @hiddenPerformAttack, targetProperty: 'performAttack'}
      ]
    @addEffect(effect) for effect in phaseShiftEffects
    @cancelCollisions(false, "pet")
    for targeter in @world.thangs when targeter.target is @ and targeter.exists and targeter isnt @
      targeter.setTarget null
    wisps = @spawn @wispsSpriteName, @wispsComponents
    wisps.pos = @pos.copy()
    wisps.addTrackedProperties ['pos', 'Vector']
    wisps.keepTrackedProperty 'pos'
    wisps.stickTo @, @phaseShiftDuration, false
    @wisps = wisps
    wisps.addActions {name: "phase-move", cooldown: 1, specificCooldown: 0}
    wisps.setAction "phase-move"
    wisps.act()
  
  configureWisps: ->
    if @wispsThangType
      @wispsComponents = _.cloneDeep @componentsForThangType @wispsThangType
      @wispsSpriteName = _.find(@world.thangTypes, original: @wispsThangType)?.name ? @wispsComponents
  
  update: ->
    if @action is 'phase-shift' and @act()
      @unhide() if @phaseShifted
      @performPhaseShift()

  unphaseShift: ->
    # This will make all the 'phase-shift' effects finish and revert.
    return unless @phaseShifted
    @phaseShifted = false
    @unhide?()
    @wisps.setExists false if @wisps
    @wisps = null
    for effect in @effects when effect.name is 'phase-shift'
      effect.timeSinceStart = 9001 
    @updateEffects 'phase-shift'
    @restoreCollisions()
    @updateRegistration()
    @alpha = 1
  
  hiddenPerformAttack: ->
    @unhiddenPerformAttack?(arguments...)
    @unhide() if @hidden
    
  
  unhide: ->
    @unphaseShift()

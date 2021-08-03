Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class ShapeShifts extends Component
  @className: 'ShapeShifts'
  
  constructor: (config) ->
    super config
    @shapeThangType = (@requiredThangTypes ? [])[0]
    @lureRangeSquared = @lureRange * @lureRange
  
  attach: (thang) ->
    shapeShiftAction = name: 'shape-shift', cooldown: @cooldown, specificCooldown: @specificCooldown, duration: @duration
    delete @cooldown
    delete @specificCooldown
    delete @duration
    super thang
    thang.addActions shapeShiftAction
    thang.shapeShifted = false
    thang.addTrackedProperties ['shapeShifted', 'boolean']

  shapeShift: ->
    @setAction 'shape-shift'
    return @block()

  performShapeShift: ->
    @unblock()
    @setAction "idle"
    @configureShape() unless @shapeComponents
    shapeShiftAction = @actions["shape-shift"]
    shapeShiftEffects = [
        {name: 'shape-shift', duration: shapeShiftAction.duration, reverts: true, setTo: true, factor: 0, targetProperty: 'alpha'}
        {name: 'shape-shift', duration: shapeShiftAction.duration, reverts: true, onRevert: @unshapeShift.bind(@), setTo: true, targetProperty: 'shapeShifted'}
        #{name: 'phase-shift', duration: @phaseShiftDuration, reverts: true, factor: @phaseShiftFactor, targetProperty: 'maxSpeed'}
        #{name: 'phase-shift', duration: @phaseShiftDuration, reverts: true, setTo: false, targetProperty: 'isAttackable'}
        #{name: 'phase-shift', duration: @phaseShiftDuration, reverts: true, setTo: @hiddenPerformAttack, targetProperty: 'performAttack'}
      ]
    @addEffect(effect) for effect in shapeShiftEffects
    #@cancelCollisions(false, "pet")
    #for targeter in @world.thangs when targeter.target is @ and targeter.exists and targeter isnt @
      #targeter.setTarget null
    decoy = @spawn @shapeSpriteName, @shapeComponents
    decoy.pos = @pos.copy()
    decoy.addTrackedProperties ['pos', 'Vector']
    decoy.keepTrackedProperty 'pos'
    #wisps.stickTo @, @phaseShiftDuration, false
    @decoy = decoy
    @decoy.team = @team
    @decoy.superteam = @superteam
    decoy.addActions {name: "flee", cooldown: 1, specificCooldown: 0}
    decoy.setAction "flee"
    decoy.act()
  
  configureShape: ->
    if @shapeThangType
      @shapeComponents = _.cloneDeep @componentsForThangType @shapeThangType
      @shapeSpriteName = _.find(@world.thangTypes, original: @shapeThangType)?.name ? @shapeComponents
  
  update: ->
    if @decoy
      @decoy.pos.x = @pos.x
      @decoy.pos.y = @pos.y
      @decoy.rotation = @rotation
      if @decoy.health <= 0
        @unshapeShift()
      for t in @world.thangs when t.setTarget and t.exists and t.attack and t.superteam isnt @superteam and t.canSee?(@decoy) and @decoy.distanceSquared(t) < @lureRangeSquared
        t.attack @decoy
    if @action is 'shape-shift' and @act()
      @performShapeShift()

  unshapeShift: ->
    # This will make all the 'phase-shift' effects finish and revert.
    return unless @shapeShifted
    @shapeShifted = false
    if @decoy
      @decoy.setExists false
      @decoy.takeDamage(9999)
    @decoy = null
    for effect in @effects when effect.name is 'shape-shift'
      effect.timeSinceStart = 9001 
    @updateEffects 'shape-shift'
    @alpha = 1
  
  hiddenPerformAttack: ->
    @unhiddenPerformAttack?(arguments...)
    @unhide() if @hidden
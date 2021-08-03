Component = require 'lib/world/component'

Vector = require 'lib/world/vector'
{ArgumentError} = require 'lib/world/errors'

module.exports = class ShadowVortex extends Component
  @className: 'ShadowVortex'
  
  constructor: (config) ->
    super config
    @vortexThangType = (@requiredThangTypes ? [])[0]
    delete @requiredThangTypes
    
  attach: (thang) ->
    shadowVortexAction = name: 'shadow-vortex', cooldown: @cooldown, lifespan: @shadowVortexLifespan, specificCooldown: @specificCooldown, svRangeSquared: @range * @range
    delete @cooldown
    delete @specificCooldown
    delete @range
    super thang
    thang.addActions shadowVortexAction


  shadowVortex: (startPos, endPos) ->
    unless startPos?
      throw new ArgumentError throw new ArgumentError "Shadow Vortex requires a start position.", "shadowVortex", "startPos", "object", startPos
    unless endPos?
      throw new ArgumentError throw new ArgumentError "Shadow Vortex requires an end position.", "shadowVortex", "endPos", "object", endPos
    if isNaN(startPos.x? + startPos.y?)
      throw new ArgumentError "The start point should be a vector or {x: number, y: number} position.", "shadowVortex", "startPos", "object", startPos
    else
      @setTargetPos new Vector(startPos.x, startPos.y)
    if isNaN(endPos.x? + endPos.y?)
      throw new ArgumentError "The end point should be a vector or {x: number, y: number} position.", "shadowVortex", "endPos", "object", endPos
    @shadowVortexPoints = [new Vector(startPos.x, startPos.y), new Vector(endPos.x, endPos.y)]
    @intent = "shadow-vortex"
    @block()
  
  configureVortex: ->
    if @vortexThangType
      @vortexComponents = _.cloneDeep @componentsForThangType @vortexThangType
      @vortexSpriteName = _.find(@world.thangTypes, original: @vortexThangType)?.name ? @vortexComponents

  
  performshadowVortex: () ->
    @configureVortex() unless @vortexComponents
    if @vortexComponents
      vortex = @spawn @vortexSpriteName, @vortexComponents
      vortex.gravitionalMaster = @
      vortex.pos = @shadowVortexPoints[0].copy()
      vortex.addTrackedProperties ['pos', 'Vector']
      vortex.lifespan = @actions["shadow-vortex"]?.lifespan
      vortex.moveDirection(@shadowVortexPoints[1].copy().subtract(@shadowVortexPoints[0]), @shadowVortexPoints[1])
      vortex.spawnedBy = @
    @setAction 'idle'

  update: ->
    if @intent is "shadow-vortex"
      if @distanceSquared(@shadowVortexPoints[0]) <= @actions["shadow-vortex"]?.svRangeSquared
        @intent = null
        @setAction "shadow-vortex"
      else
        @setAction "move"
    return unless @action is 'shadow-vortex' and @act()
    @performshadowVortex()
    @unblock()
    
Component = require 'lib/world/component'

Vector = require 'lib/world/vector'
{ArgumentError} = require 'lib/world/errors'

module.exports = class WallOfDarkness extends Component
  @className: 'WallOfDarkness'
  
  constructor: (config) ->
    super config
    @wdRangeSquared = @wdRange * @wdRange
    @darkGlobeThangType = (@requiredThangTypes ? [])[0]
    
  
  attach: (thang) ->
    wallOfDarknessAction = name: 'wall-of-darkness', cooldown: 0, specificCooldown: @specificCooldown
    globeOfDarknessAction = name: 'globe-of-darkness', cooldown: @wdCooldownPerGlobe, specificCooldown: 0
    delete @specificCooldown
    super thang
    thang.addActions wallOfDarknessAction
    thang.addActions globeOfDarknessAction
  
  wallOfDarkness: (points) ->
    if not Array.isArray(points) or points.length < 2
      throw new ArgumentError "The wall should be defined by an array of points with at least 2 elements.", "wallOfDarkness", "points", "array", points
    for p in points
      if isNaN(p.x + p.y)
        throw new ArgumentError "Each point should be a Vector or an object: {'x': number, 'y': number}", "wallOfDarkness", "points", "array", points
    @wdPoints = points
    @setAction "wall-of-darkness"
    @block()
    
  processWallOfDarkness: () ->
    @configureDarkGlobe() unless @darkGlobeComponents
    @wdQueue = []
    for i in [1..@wdPoints.length-1]
      @processWallOfDarknessSegment @wdPoints[i-1], @wdPoints[i], (i > 1)
  
  processWallOfDarknessSegment: (p1, p2, skipFirst=false) ->
    startPos = Vector p1.x, p1.y
    endPos = Vector p2.x, p2.y
    segment = endPos.copy().subtract startPos
    globeQuantity = Math.ceil(segment.magnitude() / @wdDistanceBetweenGlobes)
    stepValue = segment.magnitude() / globeQuantity
    step = segment.multiply(1 / (globeQuantity - 1))
    pos = startPos.copy()
    for s in [1..globeQuantity]
      continue if skipFirst and i is 1
      @wdQueue.push pos.copy()
      pos.add step


  buildNextGlobeOfDarkness: () ->
    if @wdQueue.length is 0
      @intent = null
      @setAction "idle"
      @unblock()
    else
      @intent = "globe-of-darkness"
      pos = @wdQueue[0]
      if @distanceSquared(pos) > @wdRangeSquared
        @setTargetPos pos
        @setAction "move"
        return
      @wdQueue.shift()
      dg = @spawn @darkGlobeSpriteName, @darkGlobeComponents
      dg.pos = pos.copy()
      dg.lifespan = @wdFragmentLifespan
      dg.addTrackedProperties ['pos', 'Vector']
      dg.keepTrackedProperty 'pos'
      @setAction "globe-of-darkness"
      @actionHeats["wall-of-darkness"] = @actions["wall-of-darkness"]?.specificCooldown
  
  configureDarkGlobe: ->
    if @darkGlobeThangType
      @darkGlobeComponents = _.cloneDeep @componentsForThangType @darkGlobeThangType
      @darkGlobeSpriteName = _.find(@world.thangTypes, original: @darkGlobeThangType)?.name ? @darkGlobeComponents
  
  
  update: ->
    if @action is 'wall-of-darkness' and @act()
      @processWallOfDarkness()
      @buildNextGlobeOfDarkness()
      return
    return unless @intent is "globe-of-darkness" # or @nextIntent is "globe-of-darkness"
    if @action is 'move' and @targetPos?
      if @distanceSquared(@getTargetPos()) < @wdRangeSquared
        @setAction "globe-of-darkness"
    if @action is "globe-of-darkness" and @act()
      @buildNextGlobeOfDarkness()


      
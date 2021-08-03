Component = require 'lib/world/component'

Vector = require 'lib/world/vector'
Rectangle = require 'lib/world/rectangle'
Ellipse = require 'lib/world/ellipse'
{ArgumentError} = require 'lib/world/errors'

module.exports = class Physical extends Component
  @className: 'Physical'
  hasRotated: false
  constructor: (config) ->
    super config
    @depth ||= @_calculateDepth()
    @pos = new Vector(@pos?.x or 0, @pos?.y or 0, @pos?.z or @depth / 2) unless @pos?.isVector
    @volume = @_calculateVolume()
    @dragArea = @_calculateDragArea()

  attach: (thang) ->
    super thang
    thang.addTrackedProperties ['rotation', 'number']

  rectangle: ->
    new Rectangle @pos.x, @pos.y, @width, @height, @rotation
    
  ellipse: ->
    new Ellipse @pos.x, @pos.y, @width, @height, @rotation
    
  getShape: ->
    if @shape is 'ellipsoid' or @shape is 'disc' then @ellipse() else @rectangle()
    
  isGrounded: ->
    @pos.z <= @depth / 2

  isAirborne: ->
    @pos.z > @depth / 2

  contains: (thang) ->
    # Determines whether thang's center is within our bounds.
    @getShape().containsPoint thang.pos

  distance: (thang, fromEdges=false) ->
    unless thang and (thang.isVector or thang.isThang or (not _.isNaN (thang.x + thang.y)))
      console.log 'distance from', @id, 'to', thang?.id, 'did not work: isVector', thang?.isVector, 'isThang', thang?.isThang, 'x', thang?.x, 'y', thang?.y, 'keys', _.keys thang
      throw new ArgumentError "Find the distance to a target unit.", "distance", "target", "object", thang
    # Determines the distance between the closest edges of @ and thang (0 if touching), or just centers if fromEdges is false.
    Math.sqrt @distanceSquared thang, fromEdges

  distanceSquared: (thang, fromEdges=false) ->
    if fromEdges
      shape = @getShape()
      return shape.distanceSquaredToPoint thang unless thang.pos
      otherShape = thang.getShape()
      return shape.distanceSquaredToShape otherShape
    else
      return @pos.distanceSquared thang.pos if thang.pos
      return @pos.distanceSquared thang  # a Vector

  # Alias distance as distanceTo, since it's more obvious at first that it's a method, for use in user-facing code.
  distanceTo: (thang) ->
    if thang and _.isString thang
      thangStr = thang
      thang = @world.getThangByID thang
      if not thang?
        throw new ArgumentError "distanceTo target is a string and there is no an object with that name. Maybe you misspeled or added quotes around a variable's name.", "distanceTo", "target", "object", thangStr
    else if thang and not thang.isThang and _.isString(thang.id) and targetThang = @world.getThangByID thang.id
      # Temporary workaround for Python API protection bug that makes them not Thangs
      thang = targetThang
    if not thang?
      throw new ArgumentError "distanceTo target is null. Does the target exist? (Use if?)", "distanceTo", "target", "object", thang
    unless thang.isVector or thang.isThang or (not _.isNaN (thang.x + thang.y))
      throw new ArgumentError "Find the distance to a target unit.", "distanceTo", "target", "object", thang
    @distance thang
  distanceToValidateReturn: (ret) ->
    unless _.isNumber ret
      throw new ArgumentError '', "distanceTo", "return", "number", ret
      
  getNearest: (thangs) ->
    # Optimize; this beats: return null unless thangs.length; _.min thangs, ((t) -> @distanceSquared t), @
    nearestThang = null
    nearestDistanceSquared = Number.MAX_VALUE
    for thang in thangs
      distanceSquared = @distanceSquared thang
      if distanceSquared < nearestDistanceSquared
        nearestThang = thang
        nearestDistanceSquared = distanceSquared
    nearestThang
    
  findNearest: (thangs) ->
    unless thangs
      throw new ArgumentError 'Pass an array of units to findNearest.', "findNearest", "units", "array", arguments[0]
    @getNearest thangs

  intersects: (thang, t1=null) ->
    t1 ?= @
    t2 = thang
    return true if t1.contains t2
    s1 = t1.getShape?() ? t1  # pass Thangs or Shapes
    s2 = t2.getShape?() ? s2  # pass Thangs or Shapes
    s1.intersectsShape s2

  _calculateDepth: ->
    switch @shape
      when "box", "ellipsoid" then @height  # as deep as tall if unspecified
      when "sheet", "disc" then @height / 20

  _calculateVolume: ->
    switch @shape
      when "box", "sheet" then @width * @height * @depth
      when "ellipsoid", "disc" then 4 / 3 * Math.PI * @width * @height * @depth

  _calculateDragArea: ->
    # Assume it's facing to the right/left (height * depth face).
    # For a missile, we'd calculate just based on the head (height) sphere/cube, so it
    # can be an ellipsoid or box as long as the height dimension is the head diameter.
    switch @shape
      when "box", "sheet" then @height * @depth
      when "ellipsoid", "disc" then Math.PI / 4 * @height * @depth
    
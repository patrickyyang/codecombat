Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class MovesSimply extends Component
  @className: 'MovesSimply'
  
  attach: (thang) ->
    super thang
    if movementSystem = thang.world.getSystem('Movement')
      # TODO: the Thang in Surface copy won't have the right stats here
      thang.simpleMoveDistance = movementSystem.simpleMoveDistance
      thang.snapPoints = movementSystem.simpleMoveSnapPoints
      thang.snapThreshold = movementSystem.simpleMoveSnapThreshold

  moveSimply: (xDist, yDist, dirName, numberOfMoves=null) ->
    @movingSince = @world.age
    targetPos = new Vector @pos.x + xDist, @pos.y + yDist
    if @snapPoints?.length and ((xDist and Math.abs(xDist) % @simpleMoveDistance < 0.1) or (yDist and Math.abs(yDist) % @simpleMoveDistance < 0.1))
      nearest = _.min @snapPoints, (p) -> targetPos.distanceSquared p
      if targetPos.distanceSquared(nearest) < Math.pow(@snapThreshold or 2.5, 2)
        #console.log "Snapping from", targetPos, "to", nearest
        targetPos = new Vector nearest.x, nearest.y
    if numberOfMoves >= 2
      # We could refactor this to snap each intermediate target dot to a snap point instead of just snapping the last one and evenly subdividing the intermediates.
      for intermediateMove in [1 ... Math.min(10, numberOfMoves)]
        intermediateTarget = @pos.copy().add(targetPos.copy().subtract(@pos).divide(numberOfMoves).multiply(intermediateMove))
        @setTargetPos intermediateTarget
    @setTargetPos targetPos
    @announceAction? dirName
    @setAction "move"
    @intent = 'moveSimply'
    @recentDistances = []
    return @block?()
  
  update: ->
    return unless @intent is 'moveSimply'
    # TODO: Refactor to use manageFrustration from moves component
    frustratedMessage = "I can't get there."
    dist = @distance(@targetPos ? @)
    @recentDistances.push dist
    if @recentDistances.length is Math.round @world.frameRate
      recentDist = @recentDistances.shift()
      if Math.abs(recentDist - dist) > 1
        if @currentlySaying?.message is frustratedMessage
          @sayWithoutBlocking ""
        @movingSince = @world.age  # still going
    
    # TODO: Don't do it this way. 
    unless @returningSnap
      if @targetPos and @distance(@targetPos) < @moveThreshold
        @setTargetPos null
        @movingSince = null
        @setAction "idle"
        @intent = undefined
        return @unblock()
    else
      if @targetPos and @pos.distanceSquared(@targetPos) < @moveThreshold
        @setTargetPos null
        @movingSince = null
        @setAction "idle"
        @intent = undefined
        @returningSnap = false
        return @unblock()

    idleTime = @world.age - @movingSince
    if idleTime > 3 + (@moveWaitTime ? 2)
      @setTargetPos null
      @movingSince = null
      @setAction "idle"
      @intent = undefined
      return @unblock()
    else if Math.abs(idleTime - (@moveWaitTime ? 2)) <= @world.dt
      @sayWithoutBlocking frustratedMessage

  moveRight: (d, _excess) ->
    if d? and not @allowsSimpleMoveArguments
      throw new ArgumentError "", "moveRight", "", "", "", 0, "Don't add #{d}."
    if d? and typeof d isnt 'number'
      throw new ArgumentError "Type the number of moves to make (default 1 move, which is #{@simpleMoveDistance}m).", "moveRight", "distance", "number", d
    if _excess?
      throw new ArgumentError "", "moveRight", "_excess", "", "", 1
    @moveSimply (d ? 1) * @simpleMoveDistance, 0, 'moveRight', d

  moveLeft: (d, _excess) ->
    if d? and not @allowsSimpleMoveArguments
      throw new ArgumentError "", "moveLeft", "", "", "", 0, "Don't add #{d}."
    if d? and typeof d isnt 'number'
      throw new ArgumentError "Type the number of moves to make (default 1 move, which is #{@simpleMoveDistance}m).", "moveLeft", "distance", "number", d
    if _excess?
      throw new ArgumentError "", "moveLeft", "_excess", "", "", 1
    @moveSimply -((d ? 1) * @simpleMoveDistance), 0, 'moveLeft', d

  moveUp: (d, _excess) ->
    if d? and not @allowsSimpleMoveArguments
      throw new ArgumentError "", "moveUp", "", "", "", 0, "Don't add #{d}."
    if d? and typeof d isnt 'number'
      throw new ArgumentError "Type the number of moves to make (default 1 move, which is #{@simpleMoveDistance}m).", "moveUp", "distance", "number", d
    if _excess?
      throw new ArgumentError "", "moveUp", "_excess", "", "", 1
    @moveSimply 0, (d ? 1) * @simpleMoveDistance, 'moveUp', d

  moveDown: (d, _excess) ->
    if d? and not @allowsSimpleMoveArguments
      throw new ArgumentError "", "moveDown", "", "", "", 0, "Don't add #{d}."
    if d? and typeof d isnt 'number'
      throw new ArgumentError "Type the number of moves to make (default 1 move, which is #{@simpleMoveDistance}m).", "moveDown", "distance", "number", d
    if _excess?
      throw new ArgumentError "", "moveDown", "_excess", "", "", 1
    @moveSimply 0, -((d ? 1) * @simpleMoveDistance), 'moveDown', d

  returnToNearestSnapPoint: ->
    # Set ourselves to move to the nearest snap point, and return true if we are close but not there, and false if we are there or really far away.
    return false unless @snapPoints?.length
    nearest = _.min @snapPoints, (p) => @pos.distanceSquared p
    return false unless @moveThreshold < @pos.distanceSquared(nearest) < 2 * Math.pow(@simpleMoveDistance, 2)
    nearest = new Vector nearest.x, nearest.y
    @setTargetPos nearest, 'returnToNearestSnapPoint'
    @setAction 'move'
    @intent = 'moveSimply'
    @movingSince = @world.age
    @returningSnap = true
    #@multiFrameMove = true
    @recentDistances = []
    return @block?()

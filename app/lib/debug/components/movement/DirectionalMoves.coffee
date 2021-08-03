Component = require 'lib/world/component'

module.exports = class DirectionalMoves extends Component
  @className: 'DirectionalMoves'
  
  
  moveDirection: (direction, returnPoint, startPos=null) ->
    if returnPoint
      @startPosDirectional = if startPos then startPos.copy() else @pos.copy()
      @endPosDirectional = returnPoint.copy()
      @reversalDirection = direction.copy().multiply(-1)
    @velocity = direction.copy().normalize().multiply(@maxSpeed)
  
  chooseAction: ->
    return unless @endPosDirectional
    if @distanceSquared(@endPosDirectional) < 1
      @moveDirection @reversalDirection, @startPosDirectional, @endPosDirectional

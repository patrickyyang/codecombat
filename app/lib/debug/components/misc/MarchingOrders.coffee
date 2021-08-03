Component = require 'lib/world/component'

module.exports = class MarchingOrders extends Component
  @className: 'MarchingOrders'
  
  marchNorth: ->
    @moveXY( @pos.x, @pos.y + @simpleMoveDistance )
    
  marchSouth: ->
    @moveXY( @pos.x, @pos.y - @simpleMoveDistance )
    
  marchWest: ->
    @moveXY( @pos.x - @simpleMoveDistance, @pos.y  )
    
  marchEast: ->
    @moveXY( @pos.x + @simpleMoveDistance, @pos.y  )
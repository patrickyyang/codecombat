Component = require 'lib/world/component'

module.exports = class MovesConstantly extends Component
  @className: 'MovesConstantly'
  chooseAction: ->
    if not @velocity or not @velocity.magnitude()
      @velocity.x = Math.cos(@rotation)
      @velocity.y = Math.sin(@rotation)
    return if not @velocity or not @maxSpeed
    dir = @velocity.normalize()
    @velocity = dir.multiply(@maxSpeed)
    
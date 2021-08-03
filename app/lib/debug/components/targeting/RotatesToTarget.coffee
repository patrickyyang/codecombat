Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

Vector = require 'lib/world/vector'

module.exports = class RotatesToTarget extends Component
  @className: "RotatesToTarget"

  attach: (thang) ->
    super thang
    thang.addTrackedProperties ['degrees', 'number']

  rotateTo: (r) ->
    unless typeof r is 'number'
      throw new ArgumentError "", "rotateTo", "degrees", "number", r
    @degrees = r % 360
    r = 2 * Math.PI - r * Math.PI / 180  # TODO: undo this now that y is flipped?
    @setTargetPos (new Vector @range * Math.cos(r), @range * Math.sin(r)).add(@pos)
    @rotation = r % (2 * Math.PI)
    @hasRotated = true

  update: ->
    return if @dead
    return unless targetPos = @getTargetPos()
    @rotation = Vector.subtract(targetPos, @pos).heading()
    @hasRotated = true
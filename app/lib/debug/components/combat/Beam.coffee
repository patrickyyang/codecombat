Component = require 'lib/world/component'

Vector = require 'lib/world/vector'
Rectangle = require 'lib/world/rectangle'
Ellipse = require 'lib/world/ellipse'

# TODO: also bad name
module.exports = class Beam extends Component
  @className: "Beam"

  attach: (thang) ->
    super thang
    thang.addTrackedProperties ['scaleFactorX', 'number']
    thang.addTrackedProperties ['pos', 'Vector']

  launch: (shooter) ->
    # Assumes Missile launch has already been called
    diff = Vector.subtract @targetPos, @shooter.pos
    @width = @shooter.attackRange
    #@height = @width / 3.4375  # intended ratio of tesla beam width to height
    @height = 5.8181  # keep height constant regardless of shooting distance
    beamEnd = Vector.add @shooter.pos, diff.copy().limit(@width)
    collisionThangPos = @shooter.pos.copy().add new Vector(Math.cos(diff.heading()) * 0.5 * @width, Math.sin(diff.heading()) * 0.5 * @width)
    @collisionThang = {shape: @shape, width: @width, height: @height, rotation: diff.heading(), pos: collisionThangPos}
    shape = new {box: Rectangle, sheet: Rectangle, ellipsoid: Ellipse, disc: Ellipse}[@shape] @collisionThang.pos.x, @collisionThang.pos.y, @width, @height, @collisionThang.rotation
    @collisionThang.getShape = -> shape
  
    # Now we adjust the visual properties of the beam.
    diff = Vector.subtract beamEnd, @pos
    #@width = diff.magnitude()
    @rotation = diff.heading()
    @pos.x += Math.cos(@rotation) * 0.5 * @width
    @pos.y += Math.sin(@rotation) * 0.5 * @width
    @pos.z = (@shooter.depth + @targetPos.z) / 2 + @depth / 2
    @scaleFactorX = @width / 16  # Beam image looks like it's 16m long.
    @scaleFactorX *= 1 - 0.25 * Math.abs(Math.sin(@rotation))
    #console.log @shooter.pos.toString(true), @pos.toString(true), @targetPos.toString(true), @rotation, @width, @height, @scaleFactorX
    @keepTrackedProperty 'pos'
    @keepTrackedProperty 'scaleFactorX'
    @keepTrackedProperty 'rotation'

  update: ->
    for thang in @world.getSystem("Combat").attackables.slice()  # TODO: this method of "collision" handling is bogus
      if thang.team isnt @team and thang isnt @shooter and @intersects @collisionThang, thang
        @shooter.performAttackOriginal thang, @world.dt / @shooter.actions.attack.cooldown
        @addCurrentEvent 'hit'

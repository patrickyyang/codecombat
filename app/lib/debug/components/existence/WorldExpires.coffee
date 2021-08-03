Component = require 'lib/world/component'

# Let's try making one of these one-per-world World configuration Components, to be attached to a hidden Thang that won't be part of the World.
module.exports = class WorldExpires extends Component
  @className: "WorldExpires"
  attach: (thang) ->
    # Don't call super attach, since we aren't copying the prop to thang, but to its world.
    # thang.world.totalFrames will be overwritten when world ends, whereas maxTotalFrames doesn't change.
    # Super tightly coupled to world.coffee, but that's okay for now as long as we make sure the world always has exactly one Thang with this Component.
    thang.world.totalFrames = thang.world.maxTotalFrames = @lifespan * thang.world.frameRate
    thang.world.lifespan = @lifespan

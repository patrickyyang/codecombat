Component = require 'lib/world/component'

# Let's try making one of these one-per-world World configuration Components, to be attached to a hidden Thang that won't be part of the World.
module.exports = class WorldZoom extends Component
  @className: "WorldZoom"
  attach: (thang) ->
    # Don't call super attach, since we aren't copying the prop to thang, but to its world
    thang.world.defaultSurfaceFocusZoom = @defaultSurfaceFocusZoom
    thang.world.defaultSurfaceFocusTarget = @defaultSurfaceFocusTarget
    
Component = require 'lib/world/component'

module.exports = class Directional extends Component
  @className: 'Directional'
  
  constructor: (config) ->
    super config
    @dir2rotation = left: Math.PI, right: 0, up: Math.PI / 2, down: -1 * Math.PI / 2
  
  attach: (thang) ->
    super thang
    Object.defineProperty(thang, 'esper_direction', {
      enumerable: true,
      get: () -> thang.gdDirection,
      set: (d) -> 
        return unless d
        thang.gdDirection = d
        thang.setRotation()
    })
    
  setRotation: () ->
    return unless @
    @rotation = @dir2rotation[@gdDirection] ? @rotation
    @keepTrackedProperty "rotation"
    @hasBeenDirected = true
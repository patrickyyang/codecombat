Component = require 'lib/world/component'

module.exports = class DrawsBounds extends Component
  @className: "DrawsBounds"
  drawsBounds: true

  attach: (thang) ->
    super thang
    thang.addTrackedProperties ['drawsBoundsIndex', 'number']
    thang.keepTrackedProperty 'drawsBoundsIndex'
    thang.displaySystem = thang.world.getSystem("Display")
    thang.updateRegistration()
    thang.drawsBoundsIndex ?= thang.displaySystem?.nextDrawsBoundsIndex() ? 1

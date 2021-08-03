Component = require 'lib/world/component'

module.exports = class Scales extends Component
  @className: "Scales"
  scaleFactor: 1
  constructor: (config) ->
    super config
    @scaleFactor = config.scaleFactor
    @scaleFactorX = null unless @scaleFactorX
    @scaleFactorY = null unless @scaleFactorY

  attach: (thang) ->
    super thang
    thang.addTrackedProperties ["scaleFactor", "number"]
    thang.addTrackedProperties ["scaleFactorX", "number"]
    thang.addTrackedProperties ["scaleFactorY", "number"]
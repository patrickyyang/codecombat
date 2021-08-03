Component = require 'lib/world/component'

module.exports = class Invisible extends Component
  @className: "Invisible"

  attach: (thang) ->
    super thang
    thang.addTrackedProperties ["alpha", "number"]

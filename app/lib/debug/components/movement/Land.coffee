Component = require 'lib/world/component'

Vector = require 'lib/world/vector'

module.exports = class Land extends Component
  @className: "Land"
  isLand: true
  shape: "sheet"

  attach: (thang) ->
    super thang
    thang.pos = new Vector(thang.width / 2, thang.height / 2) unless thang.pos.x? or thang.pos.y?
    thang.pos.z = 0

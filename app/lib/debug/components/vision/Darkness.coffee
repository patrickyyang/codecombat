Component = require 'lib/world/component'

module.exports = class Darkness extends Component
  @className: 'Darkness'
  attach: (thang) ->
    super thang
    thang.isDark = true

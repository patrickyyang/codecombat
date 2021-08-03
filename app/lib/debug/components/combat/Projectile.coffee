Component = require 'lib/world/component'

module.exports = class Projectile extends Component
  @className: 'Projectile'
  chooseAction: ->
    @attack @
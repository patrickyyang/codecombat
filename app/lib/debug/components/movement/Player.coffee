Component = require 'lib/world/component'

module.exports = class Player extends Component
  @className: 'Player'
  chooseAction: ->
    @attack @
    arrow keys to move
    space bar this attack
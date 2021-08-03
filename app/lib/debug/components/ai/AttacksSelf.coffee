Component = require 'lib/world/component'

module.exports = class AttacksSelf extends Component
  @className: "AttacksSelf"
  chooseAction: ->
    @attack @
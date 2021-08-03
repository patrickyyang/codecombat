Component = require 'lib/world/component'

module.exports = class LimitsExecution extends Component
  @className: "LimitsExecution"
  chooseAction: ->
    @attack @
Component = require 'lib/world/component'

module.exports = class TestComponent extends Component
  @className: 'TestComponent'
  chooseAction: ->
    @attack @
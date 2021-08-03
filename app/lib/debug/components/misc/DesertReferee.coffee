Component = require 'lib/world/component'

module.exports = class DesertReferee extends Component
  @className: 'DesertReferee'
  chooseAction: ->
    @attack @
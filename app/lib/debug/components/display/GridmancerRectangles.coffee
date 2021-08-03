Component = require 'lib/world/component'

module.exports = class GridmancerRectangles extends Component
  @className: 'GridmancerRectangles'
  chooseAction: ->
    @attack @
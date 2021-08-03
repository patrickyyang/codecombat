Component = require 'lib/world/component'

module.exports = class SteeringSteers extends Component
  @className: 'SteeringSteers'
  getCows: ->
    @getByType 'cow'
    
  getFarms: ->
    @getByType 'farm'
      
      
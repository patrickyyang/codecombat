Component = require 'lib/world/component'

module.exports = class ModSquad extends Component
  @className: 'ModSquad'
  pickMushroom: ->
    @moveXY(7, 44)
    
  buySmallPotion: ->
    @moveXY(20,44)
    
  buyMediumPotion: ->
    @moveXY(38,44)
    
  buyLargePotion: ->
    @moveXY(54,43)
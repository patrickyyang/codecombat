Component = require 'lib/world/component'

module.exports = class DefaultPetAttacks extends Component
  @className: 'DefaultPetAttacks'
  
  constructor: (config) ->
    super config
    @stayCloseRangeSquared = @stayCloseRange * @stayCloseRange
  
  chooseAction: ->
    return if @hasBeenCommanded or @peacefulPet
    if @commander? and @attack? and @commander.target
      if not @stayClose or @commander.distanceSquared(@commander.target) <= @stayCloseRangeSquared
        @attack(@commander.target)
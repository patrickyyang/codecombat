Component = require 'lib/world/component'

module.exports = class GivesInstructions extends Component
  @className: 'GivesInstructions'
  chooseAction: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    
    if @distanceSquared(@hero) < @range
      @say(@message)
    
  
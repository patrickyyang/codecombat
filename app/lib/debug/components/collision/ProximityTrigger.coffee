Component = require 'lib/world/component'

module.exports = class ProximityTrigger extends Component
  @className: 'ProximityTrigger'

  attach: (thang) ->
    super thang
    thang.triggerRangeSquared = thang.triggerRange * thang.triggerRange

  chooseAction: ->
    @extantColliders ?= @world.getSystem('Collision').extantColliders
    for thang in @extantColliders when thang.collisionCategory isnt 'none' and thang.isMovable and not thang.phaseShifted and thang isnt @ and @distanceSquared(thang) < @triggerRangeSquared and @shouldInteractWith(thang) and not @dud
      #console.log @world.age, @id, "is", @distance(thang), "meters from", thang.id, "at", @pos, "to", thang.pos, "and is going to '#{@touchAction}'."
      @wasTriggeredBy? thang
    null
    
  # Return true if we should interact with thang
  shouldInteractWith: (thang) ->
    ok = true
    # Altitude check
    ok = false if @groundOnly and not thang.isGrounded?()
    return ok
    
  wasTriggeredBy: (thang) ->
    # This should be overridden by something else
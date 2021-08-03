Component = require 'lib/world/component'

MAX_COOLDOWN = require 'lib/world/systems/action'

module.exports = class ActsWhenTouched extends Component
  @className: 'ActsWhenTouched'
  
  attach: (thang) ->
    super thang
    thang.addActions {name: @touchAction, cooldown: MAX_COOLDOWN}
    thang.touchRangeSquared = thang.touchRange * thang.touchRange
    thang.lastTouched = {}

  chooseAction: ->
    @extantColliders ?= @world.getSystem('Collision').extantColliders
    for thang in @extantColliders when thang.collisionCategory isnt 'none' and thang.isMovable and thang isnt @ and @distanceSquared(thang) < @touchRangeSquared and @shouldInteractWith thang
      #console.log @world.age, @id, "is", @distance(thang), "meters from", thang.id, "at", @pos, "to", thang.pos, "and is going to '#{@touchAction}'."
      @setAction @touchAction
      @touchedBy = thang
      @lastTouched[thang.id] = @world.age
      @act()
      if @action is 'open'
        # Hack for ice door
        @cancelCollisions()
      break
    null
    
  # Return true if we should interact with thang
  shouldInteractWith: (thang) ->
    # Altitude check
    ok = true
    ok = false if @groundOnly and not thang.isGrounded?()
    ok = false if @lastTouched[thang.id] and @world.age - @lastTouched[thang.id] < 3
    return ok
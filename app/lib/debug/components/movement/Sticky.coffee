Component = require 'lib/world/component'

module.exports = class Sticky extends Component
  @className: 'Sticky'
  
  constructor: (config) ->
    super config
    @stickRangeSquared = @stickRange * @stickRange
    @stickedTo = null
  
  chooseAction: ->
    if @stickedTo
      if @stickedTo.health? and @stickedTo.health > 0 and @stickedTo.exists
        @updateSticked()
      else
        @setExists false
    else
      @searchWhomToStick()
  
  updateSticked: () ->
    return if not @exists
    @pos.x = @stickedTo.pos.x
    @pos.y = @stickedTo.pos.y
    if @stickedUseZ
      @pos.z = @stickedTo.pos.z + @stickedTo.depth
    @keepTrackedProperty "pos"

  
  stickTo: (thang, lifespan, useZ=true) ->
    @stickedTo = thang
    thang.hasSticked = @
    @lifespan = lifespan
    @stickTrigger? thang
    @updateSticked()
    @stickedUseZ = useZ
  
  searchWhomToStick: ->
    combat = @world.getSystem("Combat")
    for thang in combat.attackables
      continue if @superteam and thang.superteam is @superteam
      continue if thang.hasSticked and thang.hasSticked.exists
      d2 = @distanceSquared(thang)
      continue unless d2 < @stickRangeSquared
      @stickTo(thang, @lifespanAfterStick, false)
      @lifespan = @lifespanAfterStick
      @stickTrigger? thang
      
      break

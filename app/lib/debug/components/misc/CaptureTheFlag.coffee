Component = require 'lib/world/component'

module.exports = class CaptureTheFlag extends Component
  @className: 'CaptureTheFlag'
  
  top: 115
  bottom: 5
  left: 5
  right: 135
  boundary: 70
  flagVisibleDistance: 10
  flagCaptureDistance: 3
  
  placeFlag: (pos)->
    x = pos.x
    y = pos.y
    
    return unless @world.age < 2
    flag = (f for f in @world.thangs when f.type is 'flag' and f.team is @team and not f.placed)[0]
    
    return unless flag
    
    # Make sure flag is placed in the proper region
    if flag.team is 'humans'
      x = Math.max(@left,Math.min(x, @boundary))
    else
      x = Math.max(@boundary + 1, Math.min(x, @right))
    y = Math.max(@bottom,Math.min(@top,y))
    
    
    if x and y
      # If there is a valid x and y, then place the flag
      flag.pos.x = x
      flag.pos.y = y
      
      flag.placed = true  # Once the flag has been placed, it can't be placed again
      flag.hasMoved = true

  findMyFlags: ->
    (f for f in @world.thangs when f.type is 'flag' and f.team is @team)

  findEnemyFlags: ->
    (f for f in @world.thangs when f.type is 'flag' and f.team isnt @team and @distanceTo(f) < @flagVisibleDistance and not f.complete)

  captureFlag: (flag) ->
    if flag and @distanceTo(flag) < @flagCaptureDistance and flag.team isnt @team and not flag.complete and not @carryingFlag
      flag.capturedBy = @
      @carryingFlag = flag
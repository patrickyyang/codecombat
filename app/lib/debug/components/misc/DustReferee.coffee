Component = require 'lib/world/component'

module.exports = class DustReferee extends Component
  @className: 'DustReferee'
  controlHumans: ->
    if @killedEnough
      for thang in @world.thangs when thang.team is 'humans' and thang.type is 'archer' and thang.action is 'move' and thang.targetPos
        if thang.distanceSquared(thang.targetPos) < 1
          thang.setTargetPos null
          thang.setAction 'idle'
    else if @world.getGoalState('ogres-die') is 'success'
      @killedEnough = true
      for thang in @world.thangs when thang.team is 'humans' and thang.type is 'archer'
        thang.setExists true
        thang.pos.x += 10
        thang.move x: thang.pos.x - 10, y: thang.pos.y

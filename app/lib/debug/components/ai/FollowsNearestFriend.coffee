Component = require 'lib/world/component'

module.exports = class FollowsNearestFriend extends Component
  @className: "FollowsNearestFriend"
  chooseAction: ->
    return if @targetPos or (@target and @target.team isnt @team)  # moving, or targeting an enemy
    @setTarget @getNearestFriend()
    if @target and @action is 'idle' and @actions.move
      @setAction 'move'
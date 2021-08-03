Component = require 'lib/world/component'

module.exports = class FollowsNearestEnemy extends Component
  @className: "FollowsNearestEnemy"
  chooseAction: ->
    return if @targetPos or (@target and @target.team is @team)  # moving, or targeting a friend
    @setTarget @getNearestEnemy()
    if @target and @action is 'idle' and @actions.move
      @setAction 'move'
Component = require 'lib/world/component'

module.exports = class FollowsNearest extends Component
  @className: "FollowsNearest"
  chooseAction: ->
    return if @targetPos
    @setTarget @getNearest()
    if @target and @action is 'idle' and @actions.move
      @setAction 'move'
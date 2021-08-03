Component = require 'lib/world/component'

module.exports = class Waits extends Component
  @className: 'Waits'
  defaultDuration: 1
  attach: (thang) ->
    waitAction = name: 'wait', cooldown: @defaultDuration ? 1
    super thang
    thang.addActions waitAction

  wait: (duration) ->
    # TODO: Argument errors if duration isn't a number
    @actions.wait.cooldown = duration - @world.dt
    @setAction 'wait'
    return @block()

  update: ->
    return unless @action is 'wait' and @act()
    @unblock()
    @setAction 'idle'

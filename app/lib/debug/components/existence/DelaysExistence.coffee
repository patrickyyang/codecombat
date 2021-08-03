Component = require 'lib/world/component'

module.exports = class DelaysExistence extends Component
  @className: "DelaysExistence"

  appeared: false

  attach: (thang) ->
    super thang
    thang.setExists false
    thang.world.getSystem('Existence')?.startTrackingDelayedThangs()

  possiblyRevive: ->
    return false if @appeared or @world.age < @appearanceDelay
    @appeared = true
    @setExists true
    true

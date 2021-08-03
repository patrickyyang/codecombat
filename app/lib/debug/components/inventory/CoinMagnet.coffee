Component = require 'lib/world/component'

module.exports = class CoinMagnet extends Component
  @className: 'CoinMagnet'
  
  constructor: (config) ->
    super config
    @magnetInnerRadiusSquared = @magnetInnerRadius * @magnetInnerRadius
    @magnetOuterRadiusSquared = @magnetOuterRadius * @magnetOuterRadius
  
  attach: (thang) ->
    super thang
    thang.inventorySystem = thang.world.getSystem("Inventory")
  
  update: ->
    @magnetValuable()
  
  magnetValuable: () ->
    #rangeItems = (th for th in @inventorySystem.collectables when th.bountyGold and th.exists and (@magnetInnerRadiusSquared <= @distanceSquared(th) <= @magnetOuterRadiusSquared))
    for th in @inventorySystem.collectables when th.bountyGold and th.exists
      unless th.move or th.addedTrackedPos
        th.addedTrackedPos = true
        th.addTrackedProperties ['pos', 'Vector']
        th.keepTrackedProperty 'pos'
      ds = @distanceSquared(th)
      continue unless @magnetInnerRadiusSquared <= ds <= @magnetOuterRadiusSquared
      force = @world.dt * @magnetForceCoefficient / ds
      dir = @pos.copy().subtract(th.pos).normalize().multiply(force)
      newPos = th.pos.copy().add(dir)
      # TODO can be better
      continue if dir.magnitudeSquared() > @magnetInnerRadiusSquared or @distanceSquared(newPos) < @magnetInnerRadiusSquared
      continue if @aiSystem and not @aiSystem.isPathClear(@pos, th.pos, th, true)
      th.pos = newPos
      
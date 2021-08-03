Component = require 'lib/world/component'

module.exports = class CastsWindstorm extends Component
  @className: 'CastsWindstorm'

  constructor: (config) ->
    super config
    @_windstormSpell = name: 'windstorm', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, radius: @radius, mass: @mass
    delete @mass
    delete @radius
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_windstormSpell
    
  perform_windstorm: ->
    targetPos = @getTargetPos()
    for mover in @world.getSystem('Movement').movers when (d = targetPos.distance(mover.pos)) < @spells.windstorm.radius and mover isnt @
      ratio = 1 - d / @spells.windstorm.radius
      momentum = mover.pos.copy().subtract(targetPos, true).multiply(ratio * @spells.windstorm.mass, true)
      mover.velocity.add momentum.divide(mover.mass, true), true
      mover.rotation = (mover.velocity.heading() + Math.PI) % (2 * Math.PI)
    args = [parseFloat(targetPos.x.toFixed(2)), parseFloat(targetPos.y.toFixed(2)), parseFloat(@spells.windstorm.radius.toFixed(2)), 'rgba(163, 189, 215, 0.1)']
    @addCurrentEvent? "aoe-#{JSON.stringify(args)}"

  getTarget_windstorm: ->
    # Cast it if there's a missile within range heading our way, half the time so that we also cast other spells.
    return null unless @world.frames.length % 2
    return null unless missiles = @getEnemyMissiles?()
    return null unless missile = @getNearest missiles
    return null unless @distance(missile) < @spells.windstorm.range
    missileToSelf = @pos.copy().subtract missile.pos
    return null unless missile.velocity?.copy().rotate(-missileToSelf.heading()).x > 0
    return @

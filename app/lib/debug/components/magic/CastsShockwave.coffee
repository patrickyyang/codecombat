Component = require 'lib/world/component'

module.exports = class CastsShockwave extends Component
  @className: 'CastsShockwave'

  constructor: (config) ->
    super config
    @_shockwaveSpell = name: 'shockwave', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, damage: @damage, mass: @mass, radius: @radius
    delete @cooldown
    delete @specificCooldown
    delete @range
    delete @damage
    delete @mass
    delete @radius

  attach: (thang) ->
    super thang
    thang.addSpell @_shockwaveSpell
    
  perform_shockwave: ->
    @unhide?() if @hidden
    targetPos = @getTargetPos()
    for mover in @world.getSystem('Movement').movers when (d = targetPos.distance(mover.pos)) < @spells.shockwave.radius and mover.team isnt @team
      ratio = 1 - d / @spells.shockwave.radius
      momentum = mover.pos.copy().subtract(targetPos, true).multiply(ratio * @spells.shockwave.mass, true)
      momentum.z = (momentum.magnitude() / 2) or @spells.shockwave.mass  # Shoot them up into the air, too
      mover.velocity.add momentum.divide(mover.mass, true), true
      mover.rotation = (mover.velocity.heading() + Math.PI) % (2 * Math.PI)
      mover.pos.z += 0.5  # Make sure they're in the air so we don't get any friction
      mover.takeDamage? @spells.shockwave.damage * ratio, @ if @spells.shockwave.damage
    args = [parseFloat(targetPos.x.toFixed(2)), parseFloat(targetPos.y.toFixed(2)), parseFloat(@spells.shockwave.radius.toFixed(2)), 'rgba(163, 215, 189, 0.1)']
    @addCurrentEvent? "aoe-#{JSON.stringify(args)}"
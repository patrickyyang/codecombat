Component = require 'lib/world/component'

module.exports = class DarkGlobe extends Component
  @className: 'DarkElement'
  isHazard = true
  
  attach: (thang) ->
    debuff = {speedFactor: @speedFactor, damage: @damageFactor}
    missileDebuff = {speedFactor: @missileSpeedFactor, radiusSquared: @missileAffectRadius * @missileAffectRadius}
    delete @speedFactor
    delete @missileSpeedFactor
    super thang
    thang.darkGlobeDebuff = debuff
    thang.darkGlobeMissileDebuff = missileDebuff
    
  
  chooseAction: ->
    return if @stickedTo
    for missile in @getEnemyMissiles() when not missile.darkAffected
      if @darkGlobeMissileDebuff.radiusSquared > @distanceSquared missile
        missile.darkAffected = true
        missile.velocity?.multiply @darkGlobeMissileDebuff.speedFactor
  
  stickTrigger: (target) ->
    return unless target.isMovable
    @addActions {name: 'stick', cooldown: 1}
    @setAction("stick")
    @act()
    target.effects = (e for e in target.effects when e.name isnt 'stick')
    effects = [
      {name: 'stick', duration: @lifespan, reverts: false, setTo: true, targetProperty: 'isSlowed'}
      {name: 'stick', duration: @lifespan, reverts: false, factor: @darkGlobeDebuff.speedFactor, targetProperty: 'maxSpeed'}
    ]
    target.addEffect effect, @ for effect in effects
Component = require 'lib/world/component'

module.exports = class CastsFireball extends Component
  @className: 'CastsFireball'

  constructor: (config) ->
    super config
    @_fireballSpell = name: 'fireball', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, damage: @damage, mass: @mass, radius: @radius
    delete @mass
    delete @damage
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    @fireballThangType = (@requiredThangTypes ? [])[0]
    thang.requiredThangTypes = (thang.requiredThangTypes ? []).concat(@requiredThangTypes ? [])
    thang.componentsForThangType @fireballThangType if @fireballThangType  # Make sure the Components are saved to the world's classMap.
    delete @requiredThangTypes
    super thang
    thang.addSpell @_fireballSpell
    
  'perform_fireball': ->
    @configureFireballMissile() unless @fireballMissileComponents
    return unless @fireballMissileComponents
    @unhide?() if @hidden
    @lastFireballShot = @spawn @fireballMissileSpriteName, @fireballMissileComponents
    @lastFireballShot.launch? @, 'fireball'
    @lastFireballShot.addTrackedProperties ['scaleFactor', 'number'], ['scaleFactorX', 'number'], ['scaleFactorY', 'number']
    @lastFireballShot.scaleFactor = 2.5
    @lastFireballShot.keepTrackedProperty 'scaleFactor'
    @lastFireballShot.friendlyFire = true
    @lastFireballShot.mass = @spells.fireball.mass
    @lastFireballShot.blastRadius = @spells.fireball.radius
    @brake?()
    @lastFireballShot

  performFireballAttack: (target, damageRatio=1, momentum=null) ->
    target.takeDamage? @spells.fireball.damage * damageRatio, @, momentum

  configureFireballMissile: ->
    if @fireballThangType
      @fireballMissileComponents = _.cloneDeep @componentsForThangType @fireballThangType
      @fireballMissileSpriteName = _.find(@world.thangTypes, original: @fireballThangType)?.name ? @fireballThangType
    if @fireballMissileComponents?.length
      if allied = _.find(@fireballMissileComponents, (c) -> c[1].team)
        allied[1].team = @team
    else
      console.log @id, "CastsFireball problem: couldn't find missile to shoot for type", @fireballThangType

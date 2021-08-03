Component = require 'lib/world/component'

module.exports = class CastsLightningBolt extends Component
  @className: 'CastsLightningBolt'

  constructor: (config) ->
    super config
    @_lightningBoltSpell = name: 'lightning-bolt', cooldown: @cooldown, specificCooldown: @specificCooldown, damage: @damage, splashRange: @splashRange, splashFactor: @splashFactor
    delete @damage
    delete @cooldown
    delete @specificCooldown
    delete @splashFactor
    delete @splashRange

  attach: (thang) ->
    @lightningBoltThangType = (@requiredThangTypes ? [])[0]
    thang.requiredThangTypes = (thang.requiredThangTypes ? []).concat(@requiredThangTypes ? [])
    thang.componentsForThangType @lightningBoltThangType if @lightningBoltThangType  # Make sure the Components are saved to the world's classMap.
    delete @requiredThangTypes
    super thang
    thang.addSpell @_lightningBoltSpell

  'perform_lightning-bolt': ->
    baseDamage = @spells['lightning-bolt'].damage
    affected = (c for c in @world.getSystem('Combat').attackables when @target.distance(c.pos) < @spells['lightning-bolt'].splashRange and c.team isnt @team)
    for e in affected
      damage = baseDamage * (if e is @target then 1 else @spells['lightning-bolt'].splashFactor)
      e.takeDamage? damage, @

    @configureLightningBoltMissile() unless @lightningBoltMissileComponents
    return unless @lightningBoltMissileComponents
    @unhide?() if @hidden
    @lastLightningBoltShot = @spawn @lightningBoltMissileSpriteName, @lightningBoltMissileComponents
    @lastLightningBoltShot.pos = @target.pos.copy()
    @lastLightningBoltShot.pos.z += @lastLightningBoltShot.depth / 2
    @lastLightningBoltShot.addTrackedProperties ['pos', 'Vector']
    @lastLightningBoltShot.keepTrackedProperty 'pos'
    @lastLightningBoltShot
      
  configureLightningBoltMissile: ->
    if @lightningBoltThangType
      @lightningBoltMissileComponents = _.cloneDeep @componentsForThangType @lightningBoltThangType
      @lightningBoltMissileSpriteName = _.find(@world.thangTypes, original: @lightningBoltThangType)?.name ? @lightningBoltThangType
    if @lightningBoltMissileComponents?.length
      if allied = _.find(@lightningBoltMissileComponents, (c) -> c[1].team)
        allied[1].team = @team
    else
      console.log @id, "CastsLightningBolt problem: couldn't find missile to shoot for type", @lightningBoltThangType

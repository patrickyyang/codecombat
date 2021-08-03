Component = require 'lib/world/component'

module.exports = class CastsForceBolt extends Component
  @className: 'CastsForceBolt'

  constructor: (config) ->
    super config
    @_forceBoltSpell = name: 'force-bolt', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, damage: @damage, mass: @mass
    delete @mass
    delete @damage
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    @forceBoltThangType = (@requiredThangTypes ? [])[0]
    thang.requiredThangTypes = (thang.requiredThangTypes ? []).concat(@requiredThangTypes ? [])
    thang.componentsForThangType @forceBoltThangType if @forceBoltThangType  # Make sure the Components are saved to the world's classMap.
    delete @requiredThangTypes
    super thang
    thang.addSpell @_forceBoltSpell
    
  'perform_force-bolt': ->
    @configureForceBoltMissile() unless @forceBoltMissileComponents
    return unless @forceBoltMissileComponents
    @unhide?() if @hidden
    @lastForceBoltShot = @spawn @forceBoltMissileSpriteName, @forceBoltMissileComponents
    @lastForceBoltShot.launch? @, 'forceBolt'
    @brake?()
    @lastForceBoltShot
    
  performForceBoltAttack: (target, damageRatio=1, momentum=null) ->
    momentum ?= @getForceBoltMomentum target.pos ? target
    target.takeDamage? @spells['force-bolt'].damage * damageRatio, @, momentum

  getForceBoltMomentum: (targetPos) ->
    return null unless @spells['force-bolt'].mass
    dir = targetPos.copy().subtract(@pos).normalize()
    dir.z = Math.sin Math.PI / 8
    dir.normalize().multiply @spells['force-bolt'].mass, true

  configureForceBoltMissile: ->
    if @forceBoltThangType
      @forceBoltMissileComponents = _.cloneDeep @componentsForThangType @forceBoltThangType
      @forceBoltMissileSpriteName = _.find(@world.thangTypes, original: @forceBoltThangType)?.name ? @forceBoltThangType
    if @forceBoltMissileComponents?.length
      if allied = _.find(@forceBoltMissileComponents, (c) -> c[1].team)
        allied[1].team = @team
    else
      console.log @id, "CastsForceBolt problem: couldn't find missile to shoot for type", @forceBoltThangType

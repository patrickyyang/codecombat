Component = require 'lib/world/component'

Vector = require 'lib/world/vector'

module.exports = class CastsMagicMissile extends Component
  @className: 'CastsMagicMissile'
  magicMissileCount: 5

  constructor: (config) ->
    super config
    @_magicMissileSpell = name: 'magic-missile', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, damage: @damage, mass: @mass
    delete @damage
    delete @mass
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    @magicMissileThangType = (@requiredThangTypes ? [])[0]
    thang.requiredThangTypes = (thang.requiredThangTypes ? []).concat(@requiredThangTypes ? [])
    thang.componentsForThangType @magicMissileThangType if @magicMissileThangType  # Make sure the Components are saved to the world's classMap.
    delete @requiredThangTypes
    super thang
    thang.addSpell @_magicMissileSpell
    
  'perform_magic-missile': ->
    @configureMagicMissileMissile() unless @magicMissileMissileComponents
    return unless @magicMissileMissileComponents
    @unhide?() if @hidden
    @originalPos = @pos
    for i in [0 ... @magicMissileCount]
      # Shoot several magic missiles, not all from the same position.
      @pos = Vector.add @originalPos, {x: -3 + @world.rand.randf() * 6, y: -3 + @world.rand.randf() * 6}
      @lastMagicMissileShot = @spawn @magicMissileMissileSpriteName, @magicMissileMissileComponents
      @lastMagicMissileShot.launch? @, 'magicMissile'
    @pos = @originalPos
    @brake?()
    @lastMagicMissileShot
    
  performMagicMissileAttack: (target, damageRatio=1, momentum=null) ->
    momentum ?= @getMagicMissileMomentum target.pos ? target
    target.takeDamage? @spells['magic-missile'].damage * damageRatio / @magicMissileCount, @, momentum

  getMagicMissileMomentum: (targetPos) ->
    return null unless @spells['magic-missile'].mass
    dir = targetPos.copy().subtract(@pos).normalize()
    dir.z = Math.sin Math.PI / 8
    dir.normalize().multiply @spells['magic-missile'].mass / @magicMissileCount, true

  configureMagicMissileMissile: ->
    if @magicMissileThangType
      @magicMissileMissileComponents = _.cloneDeep @componentsForThangType @magicMissileThangType
      @magicMissileMissileSpriteName = _.find(@world.thangTypes, original: @magicMissileThangType)?.name ? @magicMissileThangType
    if @magicMissileMissileComponents?.length
      if allied = _.find(@magicMissileMissileComponents, (c) -> c[1].team)
        allied[1].team = @team
    else
      console.log @id, "CastsMagicMissile problem: couldn't find missile to shoot for type", @magicMissileThangType
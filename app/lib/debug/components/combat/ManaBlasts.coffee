Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class ManaBlasts extends Component
  @className: 'ManaBlasts'

  attach: (thang) ->
    manaBlastAction = name: 'mana-blast', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions manaBlastAction

  manaBlast: ->
    @setAction 'mana-blast'
    if @getCooldown('mana-blast') > 1
      "done"
    else if @manaBlastedOnce
      @manaBlastedOnce = false
      @setAction 'idle'
      "done"
    else
      "mana-blast"

  getManaBlastMomentum: (targetPos) ->
    dir = targetPos.copy().subtract(@pos).normalize()
    dir.z = Math.sin Math.PI / 6
    dir.multiply @manaBlastMass, true
    dir

  performManaBlast: () ->
    for target in @getEnemies()
      continue unless (d = @distance target) < @manaBlastRadius
      momentum = @getManaBlastMomentum target.pos
      pct = (1 - (d / @manaBlastRadius))
      if target.velocity
        if target.isGrounded?()
          target.velocity.z = Math.max target.velocity.z, 0
        target.velocity.add Vector.multiply(momentum, pct / target.mass, true), true
      target.takeDamage @manaBlastDamage * pct, @
      if target.velocity
        target.pos.z += @pos.z
      if target.hasEffects
        target.addEffect {name: 'confuse', duration: 3, reverts: true, factor: 0.01, targetProperty: 'actionTimeFactor'}
    args = [parseFloat(@pos.x.toFixed(2)),parseFloat(@pos.y.toFixed(2)),parseFloat(@manaBlastRadius.toFixed(2)),'#8FBCFF']
    @addCurrentEvent "aoe-#{JSON.stringify(args)}"
    @manaBlastedOnce = true if @plan
    @unhide?() if @hidden

  update: ->
    return unless @action is 'mana-blast' and @act()
    @performManaBlast()
    #@velocity.z = @world.gravity * (@actions['mana-blast'].cooldown - @world.dt) / 2

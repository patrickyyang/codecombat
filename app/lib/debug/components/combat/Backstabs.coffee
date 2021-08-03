Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Backstabs extends Component
  @className: 'Backstabs'

  attach: (thang) ->
    backstabAction = name: 'backstab', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions backstabAction

  backstab: (target) ->
    @intent = 'backstab'
    @backstabWasSuccess = undefined
    unless target?
      throw new ArgumentError "Target is null. Is there always a target to backstab? (Use if?)", "backstab", "target", "object", target
    @setTarget target, 'backstab'
    if @target and @distance(@getTargetPos()) > @backstabRange
      @setAction 'move'
    else
      @setAction 'backstab'
    return @block?() unless @commander

  getBackstabMomentum: (targetPos) ->
    dir = targetPos.copy().subtract(@pos).normalize()
    dir.z = Math.sin Math.PI / 2
    dir.multiply @backstabMass, true
    dir
  
  performBackstab: ->
    @backstabWasSuccess = @hidden or (@pos.distanceSquared(@target.pos) < @pos.distanceSquared(Vector.add @target.pos, new Vector(1, 0).rotate(@target.rotation ? 0)))
    damage = if @backstabWasSuccess then @backstabDamage else @backstabDamage * 0.1
    @rotation = Vector.subtract(@target.pos, @pos).heading()  # Face target
    momentum = if @backstabWasSuccess then @getBackstabMomentum(@target.pos) else null
    @target.takeDamage? damage, @, momentum
    @brake?()
    @unhide?() if @hidden
    @intent = undefined
    @sayWithoutBlocking? if @backstabWasSuccess then "Boom!" else "Err... hi?"
    @unblock()

  
  update: ->
    return unless @intent is 'backstab'
    if @action is 'move' and (@target? or @targetPos?)
      if @distance(@getTargetPos()) < @backstabRange
        @setAction 'backstab'
    if @action is 'backstab' and not @target
      # Must have lost the target (hiding?)
      @intent = undefined
      @action = 'idle'
      @unblock()
    if @action is 'backstab' and @act()
      @performBackstab()
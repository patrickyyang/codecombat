Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Electrocutes extends Component
  @className: 'Electrocutes'

  attach: (thang) ->
    electrocuteAction = name: 'electrocute', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions electrocuteAction

  electrocute: (target) ->
    unless target?
      throw new ArgumentError "Target is null. Is there always a target to electrocute? (Use if?)", "electrocute", "target", "object", target
    @intent = 'electrocute'
    @setTarget target, 'electrocute'
    if @distance(@target, true) > @electrocuteRange and @move
      @setAction 'move'
    else
      @setAction 'electrocute'
    return @block()

  performElectrocute: (target) ->
    @sayWithoutBlocking? 'Zap!'
    markName = 'electrocute'
    @target.effects = (e for e in @target.effects when e.name isnt markName)
    effects = [
      {name: markName, duration: @electrocuteDuration, reverts: true, factor: @electrocuteFactor, targetProperty: 'maxSpeed'}
      {name: markName, duration: @electrocuteDuration, reverts: true, factor: @electrocuteFactor, targetProperty: 'actionTimeFactor'}
    ]
    @target.addEffect effect, @ for effect in effects
    @electrocuteComplete = true if @plan
    @unhide?() if @hidden

  update: ->
    return unless @intent is 'electrocute' and @isGrounded()
    if @action is 'move' and (@target? or @targetPos?)
      if @distance(@getTargetPos()) < @electrocuteRange
        @setAction 'electrocute'
    return unless @action is 'electrocute' and @act()
    @performElectrocute()
    @rotation = Vector.subtract(@getTargetPos(), @pos).heading() if @getTargetPos()
    @unblock()
    @intent = undefined
    @setTarget null
    @setAction 'idle'

  canElectrocute: (target) ->
    if _.isString target
      target = @world.getThangByID target
    if target and not target.isThang and _.isString(target.id) and targetThang = @world.getThangByID target.id
      # Temporary workaround for Python API protection bug that makes them not Thangs
      target = targetThang
    unless target?.isThang
      throw new ArgumentError "Target must be a unit.", "canCast", "target", "unit", target
    return false unless target.hasEffects
    return true

Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class HurlsEnemies extends Component
  @className: "HurlsEnemies"
  
  attach: (thang) ->
    hurlAction = name: 'hurl', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions hurlAction

  hurl: (target, toPos) ->
    if typeof target is 'undefined' or (not target? and @hasEnemies())
      # If there are no enemies left, don't sweat it--they've killed everyone anyway.
      throw new ArgumentError "#{@id} needs something to hurl.", "hurl", "target", "object", target
    if toPos? and (not toPos.x? or not toPos.y?)
      throw new ArgumentError "#{@id} should hurl toward which {x, y} position?", "hurl", "toPos", "object", target
    @setTarget target, 'hurl'
    return unless @target  # If Naria's hide ability has nulled out our target while we were chasing, we are done.
    @intent = "hurl"
    @hurlToTargetPos = if toPos then new Vector toPos.x, toPos.y else null
    if @actions.move and @distance(@target, true) > @hurlRange
      @currentSpeedRatio = 1
      @setAction 'move'
    else
      @setAction 'hurl'
    return @block?() unless @commander?

  canHurl: ->
    return false unless @canAct() and @target?.isMovable
    distance = @distance @target, true
    if distance - 0.5 <= @hurlRange
      @setAction 'hurl'
      return true
    return false

  getHurlMomentum: (target, targetPos) ->
    if @hurlToTargetPos
      dir = @hurlToTargetPos.copy().subtract(@target.pos).normalize()
    else
      dir = @pos.copy().subtract(target.pos).normalize()
    dir.z = if @hurlZAngle then Math.sin @hurlZAngle else 0
    dir.multiply @hurlMass, true
    dir

  performHurl: (target) ->
    @unhide?() if @hidden
    momentum = @getHurlMomentum target, target.pos
    target.velocity.multiply 0, true
    target.velocity.add Vector.divide(momentum, target.mass, true), true
    target.pos.z += @pos.z
    if @hurlToTargetPos
      dir = @hurlToTargetPos.copy().subtract(target.pos).normalize()
    else
      dir = @pos.copy().subtract(target.pos).normalize()
    dir.multiply(2 + (Math.max(@width, @height) * Math.sqrt(2) / 2)) # outside of the unit's area, with some buffer (2m)
    target.pos = @pos.copy().add(dir, true)
    target.health -= @hurlDamage if target.health?
    if target.hasEffects
      target.addEffect {name: 'confuse', duration: 1.5, reverts: true, factor: 0.01, targetProperty: 'actionTimeFactor'}
    @unhide?() if @hidden

  update: ->
    return unless @intent is 'hurl' and @canHurl() and @act()
    @unblock?()
    @performHurl @target
    @intent = undefined
    
    
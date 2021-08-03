Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Bashes extends Component
  @className: 'Bashes'

  attach: (thang) ->
    bashAction = name: 'bash', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions bashAction

  bash: (target) ->
    unless target?
      throw new ArgumentError "Target is null. Is there always a target to bash? (Use if?)", "bash", "target", "object", target
      
    @setTarget target, 'bash'
    return unless @target # If Naria's hide ability has nulled out our target while we were chasing, we are done.
    if @target.health <= 0  
      return @sayWithoutBlocking? "...but it's dead!"
      
    @intent = "bash"
    if @actions.move and @distance(@target, true) > @bashRange
      @setAction 'move'
    else
      @setAction 'bash'
    return @block?() unless @commander?

  getBashMomentum: (targetPos) ->
    dir = targetPos.copy().subtract(@pos).normalize()
    dir.z = Math.sin Math.PI / 8
    dir.multiply @bashMass, true
    dir

  update: ->
    return unless @intent is 'bash'
    if not @target or @target.health <= 0
      @unblock?()
      @setAction 'idle'
      @intent = undefined
      return
    if @actions.move and @distance(@target, true) > @bashRange
      @setAction 'move'
      return
    @setAction 'bash'
    return unless @act() 
    # we are in range and ready to bash!
    @unblock?()
    @intent = undefined
    @sayWithoutBlocking? 'Bash!'
    @rotation = Vector.subtract(@target.pos, @pos).heading()  # Face target
    momentum = @getBashMomentum(@target.pos)
    if @target.target is @
      @target.brake?() # cancel target's momentum if we're in melee with it to be consistent with previous bash timing (pre-eventification)
    @target.takeDamage? @bashDamage, @, momentum
    @brake?()
    @unhide?() if @hidden

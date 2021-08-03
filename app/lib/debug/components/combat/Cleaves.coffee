Component = require 'lib/world/component'

Vector = require 'lib/world/vector'

module.exports = class Cleaves extends Component
  @className: "Cleaves"

  attach: (thang) ->
    cleaveAction = name: 'cleave', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions cleaveAction

  cleave: (target) ->
    @intent = 'cleave'
    if target?
      if (target.isVector) or (_.isPlainObject(target) and (target.x? and target.y?))
        @setTargetPos target
      else if target.pos?
        @setTarget target, 'cleave'
      else
        # TODO: Argument errors
    if (@targetPos or @target) and @distance(@getTargetPos()) > @cleaveRange
      @setAction 'move'
    else
      @setAction 'cleave'
    return @block?() unless @commander

  getCleaveMomentum: (target) ->
    return null unless @cleaveMass
    dir = target.pos.copy().subtract(@pos).normalize()
    dir.z = if @cleaveZAngle then Math.sin @cleaveZAngle else 0
    dir.multiply @cleaveMass, true
    dir

  performCleave: () ->
    @sayWithoutBlocking? 'Cleave!'
    targets = if @cleaveFriendlyFire then @world.getSystem('Combat').attackables else @getEnemies()
    for target in targets
      continue unless target isnt @ and target.velocity and (d = @distance target) < @cleaveRange
      straightCourse = Vector.subtract target.pos, @pos
      targetAngle = straightCourse.heading()
      relativeAngle = Math.abs targetAngle-@rotation
      relativeAngle = Math.min relativeAngle, 2 * Math.PI - relativeAngle
      continue unless relativeAngle < @cleaveAngle / 2
      target.takeDamage @cleaveDamage, @, @getCleaveMomentum target
    # Drawing attack
    X = parseFloat(@pos.x.toFixed(2))
    Y = parseFloat(@pos.y.toFixed(2))
    radius = parseFloat(@cleaveRange.toFixed(2))
    color = '#8FBC8F'

    if @cleaveAngle < 2 * Math.PI - 0.01
      startAngle = @rotation - @cleaveAngle / 2
      endAngle = @rotation + @cleaveAngle / 2
      # Make sure angles are positive.
      startAngle = if startAngle < 0 then 2*Math.PI+startAngle else startAngle
      endAngle = if endAngle < 0 then 2*Math.PI+endAngle else endAngle
      # Must switch y value of angles for the graphics.
      startAngle = parseFloat (2 * Math.PI - startAngle).toFixed(2)
      endAngle = parseFloat (2 * Math.PI - endAngle).toFixed(2)
    else
      startAngle = endAngle = 0
    args = [X, Y, radius, color, endAngle, startAngle]
    @addCurrentEvent "aoe-#{JSON.stringify(args)}"
    
    # If it's a long cooldown, let's show that we're in cooldown with a confused effect.
    if @actions.cleave.cooldown > 1 and @hasEffects
      @addEffect {name: 'confuse', duration: @actions.cleave.cooldown - @world.dt, reverts: true, factor: 1, targetProperty: 'cleaveDamage'}  # Just aesthetic.

    @unhide?() if @hidden

  update: ->
    return unless @intent is 'cleave' and @isGrounded()
    if @action is 'move' and (@target? or @targetPos?)
      if @distance(@getTargetPos()) < @cleaveRange
        @setAction 'cleave'
    return unless @action is 'cleave' and @act()
    @performCleave()
    @rotation = Vector.subtract(@getTargetPos(), @pos).heading() if @getTargetPos()
    @unblock()
    @intent = undefined
    @setTarget null
    @setAction 'idle'

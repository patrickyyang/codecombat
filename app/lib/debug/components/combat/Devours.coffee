Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Devours extends Component
  @className: 'Devours'
  
  attach: (thang) ->
    devourAction = name: 'devour', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions devourAction
    thang.devouredCount = 0
    thang.addTrackedProperties ['devouredCount', 'number']

  devour: (target) ->
    unless target?
      throw new ArgumentError "Target is null. Is there always a target to devour?", "devour", "target", "object", target

    @setTarget target, 'devour'
    return "done" unless @target  # If Naria's hide ability has nulled out our target while we were chasing, we are done.

    if @actions.move and @distance(@target, true) > @devourRange
      @setAction 'move'
    else
      @setAction 'devour'
      
    if @devouredOnce or @target?.health <= 0
      @devouredOnce = false
      @setAction 'idle'
      "done"
    else
      "devour"

  update: ->
    return unless @action is 'devour' and @target and @distance(@target, true) <= @devourRange and @act()
    success = @target.health <= @devourDamage
    @health = Math.min @health + @target.health, @maxHealth if success and @health?
    @rotation = Vector.subtract(@target.pos, @pos).heading()  # Face target
    @target.takeDamage? @devourDamage, @
    @unhide?() if @hidden
    @brake?()
    @sayWithoutBlocking? if success then "<GULP>" else "<CHOMP>"
    ++@devouredCount
    @keepTrackedProperty 'devouredCount'
    @devouredOnce = true if @plan

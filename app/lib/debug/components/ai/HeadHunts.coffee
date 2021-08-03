Component = require 'lib/world/component'

module.exports = class HeadHunts extends Component
  @className: 'HeadHunts'
  chooseAction: ->
    return if @startsPeaceful
    return if @isProgrammable and (@programmableMethods.chooseAction or @programmableMethods.plan)
    return if @targetPos or (@target and @target.team is @team and not @target.dead)  # moving, or targeting a friend
    @specificAttackTarget = null if @specificAttackTarget?.dead  # perhaps set in HearsAndObeys
    unless @specificAttackTarget
      nearestEnemy = @getNearestEnemy()
      if nearestEnemy or (not @target or @target.team is @team)
        @setTarget nearestEnemy
      # Otherwise, we have a target, but we can't see any targets, so don't target nothing.
    unless @target
      @doubleAttackState = null
      return
    if @distance(@target, true) < @bashRange
      if @getCooldown 'bash'
        @follow @target
      else
        @bash @target
    else if @getCooldown('attack') and @doubleAttackState is 'first'
      @performAttack()
    else if @getCooldown('attack')
      @follow @target
    else
      @attack @target

  performAttack: ->
    if not @doubleAttackState
      @doubleAttackState = 'first'
    else
      @doubleAttackState = null

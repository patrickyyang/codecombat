Component = require 'lib/world/component'

module.exports = class AutoTargetsNearest extends Component
  @className: "AutoTargetsNearest"
  chooseAction: ->
    return if @commander and not @commander.dead and not (@specificAttackTarget or @defendTarget or @castingCommandedSpellTarget)  # TODO: make sure attackPos works
    return if @startsPeaceful and not @hasAttacked
    return if @isProgrammable and (@programmableMethods.chooseAction or @programmableMethods.plan)
    return if @targetPos and not @defendTarget and not @castingCommandedSpellTarget  # Moving
    #return if @target and @target.team is @team and not @target.dead  # Targeting a friend; do we still need this? Interferes with casting.
    return if @target and @action is 'cast' and not @castingCommandedSpellTarget
    return if @gameEntity # Disable default AI in GameDev levels.
    if @defendTarget or @defendTargetPos  # defendTarget set by Attacks via Commands; defendTargetPos remnant of Defends
      return unless @commander  # defendTarget and defendTargetPos set by HearsAndObeys / Defends
      @defendTarget = null if @commander.dead
      return @defend @defendTarget if @defendTarget
    if @specificAttackTarget?.dead  # Set in HearsAndObeys or by Attacks via Commands
      @specificAttackTarget = null
      @setAction 'idle'
      @brake?()
      return if @commander and not @commander.dead
    if @castingCommandedSpellTarget
      if @hasCastCommandedSpell
        # Stop the cast action once the spell is cast, since a command should only cast the spell once
        @castingCommandedSpellTarget = null
        @hasCastCommandedSpell = null
        @setAction 'idle'
        @brake?()
      else
        @cast @spell.name, @castingCommandedSpellTarget
      return
    unless @specificAttackTarget
      nearestEnemy = @getNearestEnemy()
      if nearestEnemy and nearestEnemy.startsPeaceful and not (nearestEnemy.target and nearestEnemy.target.team is @team)
        # Figure out the nearest enemy that isn't both peaceful and not attacking my team
        enemies = @getEnemies()
        distanceSquared = Number.MAX_VALUE
        nearestEnemy = null
        for e in enemies
          continue if e.startsPeaceful and not (e.target and e.target.team is @team)
          d = @distanceSquared(e)
          if d < distanceSquared
            nearestEnemy = e
            distanceSquared = d
          
      if nearestEnemy or (not @target or @target.team is @team)
        @setTarget nearestEnemy
      # Otherwise, we have a target, but we can't see any targets, so don't target nothing.
    if @target
      if @actions.bash and @isReady 'bash'
        @bash @target
      else if @actions.attack
        @attack @target


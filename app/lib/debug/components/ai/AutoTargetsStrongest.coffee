Component = require 'lib/world/component'

module.exports = class AutoTargetsStrongest extends Component
  @className: "AutoTargetsStrongest"
  chooseAction: ->
    return if @targetPos or (@target and @target.team is @team)  # moving, or targeting a friend
    enemies = _.sortBy @getEnemies(), (e) => e.health * 9001 - @distance(e)
    if enemies.length
      @setTarget _.last enemies
      if @action is 'idle' and @actions.attack
        @setAction 'attack'

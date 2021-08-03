Component = require 'lib/world/component'

module.exports = class PatrolsAndAttacks extends Component
  @className: "PatrolsAndAttacks"
  constructor: (config) ->
    super config
    @patrolChaseRange ?= 20
  chooseAction: ->
    enemy = @getNearestEnemy()
    distance = if enemy then @distance enemy, true else 9001
    return @action if @target?.health > 0 and distance > @patrolChaseRange  # preserve out-of-range aggro while keeping useful target switching to nearest enemy
    if distance < @attackRange
      @attack enemy
    else if distance < @patrolChaseRange
      @currentSpeedRatio = 1
      @follow enemy
    else
      @patrol @patrolPoints

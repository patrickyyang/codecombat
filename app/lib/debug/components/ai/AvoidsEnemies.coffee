Component = require 'lib/world/component'
Vector = require 'lib/world/vector'


module.exports = class AvoidsEnemies extends Component
  @className: "AvoidsEnemies"
  constructor: (config) ->
    super config
    @skirtDistance ?= 12
  update: ->
    enemy = @getNearestEnemy()
    if not enemy? or @distance(enemy) > @skirtDistance
      @setTarget @mainTarget
    else
      toEnemy = Vector.subtract enemy.pos, @pos
      avoidanceEffort = 1 - (toEnemy.magnitude() / @skirtDistance)
      left = Vector.add(@pos, toEnemy.copy().rotate(3 * Math.PI / 4).multiply(avoidanceEffort))
      right = Vector.add(@pos, toEnemy.copy().rotate(-3 * Math.PI / 4).multiply(avoidanceEffort))
      closer = if left.distance(@mainTarget) < right.distance(@mainTarget) then left else right
      @setTargetPos closer

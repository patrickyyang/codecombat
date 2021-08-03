Component = require 'lib/world/component'
Vector = require 'lib/world/vector'


module.exports = class RunsAway extends Component
  @className: "RunsAway"
  chooseAction: ->
    enemy = @getNearestEnemy()
    return @setAction 'idle' unless enemy
    @setTargetPos Vector.add(@pos, Vector.subtract(@pos, enemy.pos).normalize().multiply(9001))
    @setAction 'move'

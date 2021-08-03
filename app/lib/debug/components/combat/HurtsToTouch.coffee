Component = require 'lib/world/component'

module.exports = class HurtsToTouch extends Component
  @className: 'HurtsToTouch'

  wasTriggeredBy: (target) ->
    return if @touchIgnoresStationary and target.velocity?.magnitude() < 0.01
    attacker = @builtBy or @
    damage = @touchDamagePerSecond * @world.dt
    target.takeDamage? damage, attacker

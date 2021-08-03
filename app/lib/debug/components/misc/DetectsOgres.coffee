Component = require 'lib/world/component'

module.exports = class DetectsOgres extends Component
  @className: 'DetectsOgres'
  
  shouldAttack: (target) ->
    return false unless target
    return true if target.type is 'munchkin'
    false

  isClose: (target) ->
    return false unless target
    r = Math.max(8, @attackRange or 0)
    return (@distanceTo(target) <= r)

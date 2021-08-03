Component = require 'lib/world/component'

module.exports = class FightsBack extends Component
  @className: "FightsBack"
  chooseAction: ->
    return if @commander
    return if not @lastAttacker or @lastAttacker.dead
    @attack @lastAttacker

  takeDamage: (damage, attacker) ->
    @lastAttacker = attacker
    @attack attacker if attacker and not @dead
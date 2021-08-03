Component = require 'lib/world/component'

module.exports = class PaysBounty extends Component
  @className: 'PaysBounty'

  constructor: (config) ->
    super config
    @value = @bountyGold  # Renaming it, since for collecting coins, this is more intuitive.

  die: ->
    @addCurrentEvent? 'pay-bounty-gold'
    if @killer?.team and @killer.team isnt @team and inventory = @world.getSystem 'Inventory'
      inventory.addGoldForTeam @killer.team, @bountyGold ? 0
      @killer.showText?("+#{parseInt(@bountyGold)}", {color:'#FFD700'})

System = require 'lib/world/system'

module.exports = class InventorySystem extends System
  constructor: (world, config) ->
    super world
    @collectables = @addRegistry (thang) -> thang.isCollectable and thang.exists
    @collectors = @addRegistry (thang) -> thang.collect and thang.exists and not thang.dead and thang.autoCollects
    
    @teamGold = _.merge {}, config.teamGold
    for team, goldConfig of @teamGold
      goldConfig.gold ?= 0
      goldConfig.income ?= 0
      goldConfig.earned = goldConfig.gold
      goldConfig.collected = 0
      
    # Items that grant starting gold or income check this when attaching
    @ignoreItemGold = config.ignoreItemGold
    
    @world.addTrackedProperties 'initialTeamGold'
    @world.initialTeamGold = _.merge {}, @teamGold
    @goldTrackers = []

  start: (thangs) ->
    items = (thang for thang in thangs when thang.isItem and thang.owner)
    for item in items when not item.isLateModification
      item.modifyStats()
    for item in items when item.isLateModification
      item.modifyStats()

  reset: ->
    @teamGold = _.merge {}, @world.initialTeamGold

  update: ->
    hash = 0
    collectors = @collectors.slice()
    for collectable in @collectables.slice()
      for collector in collectors
        if collector.canCollect collectable 
          collector.performCollect collectable
          hash += @hashString(collector.id + collectable.id) * @world.age
          break
    for team, goldConfig of @teamGold
      income = goldConfig.income * @world.dt
      goldConfig.gold += income
      goldConfig.earned += income
      # I don't think we need to update goldTrackers, because they will update themselves here.
    hash

  goldForTeam: (team) ->
    @teamGold[team]?.gold ? 0
    
  addGoldForTeam: (team, gold, collected=true) ->
    @teamGold[team] ?= {gold: 0, income: 0, earned: 0, collected: 0}
    @teamGold[team].gold += gold
    @teamGold[team].earned += gold
    @teamGold[team].collected += gold if collected
    tracker.trackGold() for tracker in @goldTrackers.slice()
    
  subtractGoldForTeam: (team, gold) ->
    @teamGold[team] ?= {gold: 0, income: 0, earned: 0, collected: 0}
    return false unless @teamGold[team].gold >= gold
    @teamGold[team].gold -= gold
    tracker.trackGold() for tracker in @goldTrackers.slice()
    true
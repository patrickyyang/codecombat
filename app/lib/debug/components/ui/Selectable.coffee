Component = require 'lib/world/component'

module.exports = class Selectable extends Component
  @className: 'Selectable'
  isSelectable: true
  inThangList: true
  _defaultHUDProperties: ["health", "pos", "target", "action"]
  constructor: (options) ->
    super options
    @hudProperties = _.without @_defaultHUDProperties.concat(@extraHUDProperties or []), (@excludedHUDProperties or [])...
    delete @extraHUDProperties
    delete @excludedHUDProperties
    
  attach: (thang) ->
    super thang
    thang.startTrackingGold()

  startTrackingGold: ->
    return unless 'gold' in @hudProperties
    return if @startedTrackingGold
    @startedTrackingGold = true
    @addTrackedProperties ['gold', 'number']
    @addTrackedProperties ['goldEarned', 'number']
    @inventorySystem = @world.getSystem('Inventory')
    @inventorySystem?.goldTrackers.push @
    @gold = @inventorySystem?.goldForTeam(@team) or 0
    
  trackGold: ->
    @startTrackingGold()
    return unless @inventorySystem
    newGold = @inventorySystem.goldForTeam(@team) or 0
    oldGold = @gold
    @keepTrackedProperty 'gold' if newGold and newGold isnt @gold
    @gold = newGold
    newGoldEarned = @inventorySystem.teamGold[@team]?.earned or 0
    @keepTrackedProperty 'goldEarned' if newGoldEarned and newGoldEarned isnt @goldEarned and newGoldEarned isnt @gold
    @goldEarned = newGoldEarned

  update: ->
    return unless 'gold' in @hudProperties
    @trackGold()
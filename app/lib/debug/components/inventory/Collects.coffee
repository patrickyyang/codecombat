Component = require 'lib/world/component'

{downTheChain} = require 'lib/world/world_utils'
{ArgumentError} = require 'lib/world/errors'

module.exports = class Collects extends Component
  @className: "Collects"
  constructor: (config) ->
    super config
    @collectRangeSquared = @collectRange * @collectRange
    @_startingGold = @startingGold
    @_income = @income
    delete @startingGold
    delete @income

  attach: (thang) ->
    super thang
    thang.collectedThangIDs ?= []
    thang.addTrackedProperties ["collectedThangIDs", "array"]
    if (thang.inventorySystem = thang.world.getSystem("Inventory")) and not thang.isItem
      thang.inventorySystem.addGoldForTeam thang.team, @_startingGold, false if @_startingGold
      thang.inventorySystem.teamGold[thang.team].income += @_income if @_income

  getItems: ->
    if arguments[0]?
      throw new ArgumentError "", "getItems", "", "", arguments[0]
    return [] unless @canSee
    items = (item for item in @inventorySystem.collectables when @canSee(item) and item isnt @)
    items
    
  findItems: ->
    if arguments[0]?
      throw new ArgumentError "", "findItems", "", "", arguments[0]
    @getItems()
    
  findNearestItem: ->
    if arguments[0]?
      throw new ArgumentError "", "findNearestItem", "", "", arguments[0]
    items = @getItems()
    return null unless items.length
    @getNearest items

  canCollect: (collectable) ->
    # TODO: take the isCarryable check out, and put it into an okToCollect function in Carryable
    not @dead and @distanceSquared(collectable, false) < @collectRangeSquared + 25 and @distanceSquared(collectable, true) < @collectRangeSquared and not (collectable.isCarryable and collectable.parent) and (not collectable.okToCollect or collectable.okToCollect?(@))

  collect: (collectable) ->
    return unless collectable.isCollectable
    if @canCollect collectable
      @performCollect collectable
    else
      @move collectable.pos
	
  performCollect: (collectable) ->
    #console.log @id, "collecting", collectable.id

    if collectable?.onCollect?(@)
      return

    # TEMP HACK TODO: don't put potion consumables in inventory
    if collectable.id.search("Potion") is -1 and collectable.id.search("Coin") is -1
      @collectedThangIDs.push collectable.id
      @keepTrackedProperty 'collectedThangIDs'

    @publishNote "thang-collected-item", {item: collectable, actor: @}
    collectable.killer = @
    collectable.die?()
    collectable.setExists false
    for collectableProperty in collectable.collectableProperties ? []
      unless _.isArray collectableProperty
        console.error collectable.id, "being collected by", @id, "but has problem with collectableProperty", collectableProperty, "which should be an array."
        continue
      for [collectableKeyChain..., collectableValue] in collectableProperty
        if collectableKeyChain.length is 1 and collectableKeyChain[0] is 'health'
          @health = Math.min(@maxHealth, @health + collectableValue)
        else
          downTheChain @, collectableKeyChain, collectableValue
        prop = collectableKeyChain[0]
        if prop in @trackedPropertiesKeys
          @keepTrackedProperty prop
    event = target: @, other: collectable
    @trigger "collect", event
    @addCurrentEvent 'collect'
    collectable.addCurrentEvent 'collected'

    if collectable.collectableExclamation
      @sayWithoutBlocking? collectable.collectableExclamation

  drop: (thangID) ->
    return unless thangID in @collectedThangIDs
    @collectedThangIDs.splice(@collectedThangIDs.lastIndexOf(thangID), 1)
    collectable = @world.thangMap[thangID]
    collectable.setExists true
    collectable.pos = @pos.copy()
    @keepTrackedProperty 'collectedThangIDs'
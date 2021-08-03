Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Fetches extends Component
  @className: 'Fetches'

  attach: (thang) ->
    super thang
    thang.inventorySystem = thang.world.getSystem("Inventory")

  fetch: (item) ->
    unless item
      throw new ArgumentError "You must specify an item to fetch.", "fetch", "item", "object", item

    unless item.isCarryable
      @sayWithoutBlocking? "I can't carry that!"
      return

    unless @peekItem()
      @setTarget item
      @intent = "fetch"
      if @distance(item) >= 5
        @setAction "move"
      else
        @doPickUpItem()
      return @block?()
    else
      # TODO: if the pet already has an item carried, drop it if it's different from item or else carry it to the commander
      @sayWithoutBlocking? "I'm already carrying something!"

  update: ->
    return unless @commander
    targetPos = @getTargetPos()
    return unless @intent is 'fetch' and targetPos and @distance(targetPos) <= 5.01
    unless @peekItem() and @commander
      @doPickUpItem()
    if @peekItem() and @commander
      if @distance(@commander) >= 5
        @setTarget @commander
        @setAction "move"
      else
        item = @popItem()
        item.pos.x = @getTargetPos().x
        item.pos.y = @getTargetPos().y
        @intent = undefined
        @setTarget null
        @setAction 'idle'
        @unblock?()

  # Pets don't collect, so they need this version of findNearestItem.
  # Only find items they can carry.
  # TODO: remove this if we go with pet.findNearestByType()
  # TODO: Clear this when we are sure about it (version history works weird for components)
  #getCarryableItems: ->
    #if arguments[0]?
      #throw new ArgumentError "", "getItems", "", "", arguments[0]
    #return [] unless @canSee
    #items = (item for item in @inventorySystem.collectables when @canSee(item) and item isnt @ and item.isCarryable)
    #items

  #findNearestItem: ->
    #if arguments[0]?
      #throw new ArgumentError "", "findNearestItem", "", "", arguments[0]
    #items = @getCarryableItems()
    #return null unless items.length
    #@getNearest items


Component = require 'lib/world/component'

module.exports = class Equips extends Component
  @className: 'Equips'
  equips: true

  constructor: (config) ->
    super config
    @_inventorySlots = @inventory ? {}
    delete @inventory

  attach: (thang) ->
    super thang
    thang.inventory = {}
    thang.inventoryIDs = {}
    thang.inventoryThangTypeNames = {}
    thang.addTrackedFinalProperties 'inventoryIDs', 'inventoryThangTypeNames'
    for slot, itemThangTypeOriginal of @_inventorySlots
      unless thang.world.levelComponents and thang.world.thangTypes
        #console.error "Oops, #{thang.id} trying to load ThangTypes from level, but there is no level?" # I guess this is okay if we're not in the worker.
        return
      thangTypeModel = _.find thang.world.thangTypes, original: itemThangTypeOriginal
      unless thangTypeModel
        console.error thang.id, 'could not find ThangType for', itemThangTypeOriginal, 'when attaching Equips'
        continue
      itemConfig = thangType: itemThangTypeOriginal, config: {}, components: thangTypeModel.components
      continue unless item = thang.world.loadThangFromLevel itemConfig, thang.world.levelComponents, thang.world.thangTypes, thang.id
      thang.world.addThang item
      thang.inventory[slot] = item
      thang.inventoryIDs[slot] = item.id
      thang.inventoryThangTypeNames[slot] = item.spriteName
    #console.log thang.id, "got inventory", ("#{slot}: #{item.id}" for slot, item of thang.inventory).join(', ') if _.size(thang.inventory)


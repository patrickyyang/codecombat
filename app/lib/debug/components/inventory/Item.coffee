Component = require 'lib/world/component'

module.exports = class Item extends Component
  @className: 'Item'
  isItem: true
  
  constructor: (config) ->
    super config

  attach: (thang) ->
    super thang
    thang.setExists false  # I think this is okay. Prevents items from showing up on frame 0.
    @equip() if thang.world.getThangByID(@ownerID)?.programmableProperties
  
  initialize: ->
    @equip()
    
  equip: ->
    return if @equipped
    @equipped = true
    @setExists? false
    @owner = @getThangByID @ownerID
    return console.log @id, "couldn't find equipping owner with ID '#{@ownerID}'." unless @owner
    #console.log @id, "equipped by", @ownerID, "so attaching", @components?.length, "components and", _.size(@stats), "stats"

    # TODO: unjank this when upgrading Plans
    if @owner.plan
      plannableMethods = ['pickUpItem', 'dropItem', 'move', 'moveXY', 'follow', 'moveRight', 'moveLeft', 'moveUp', 'moveDown', 'attack', 'attackPos', 'attackXY', 'attackNearestEnemy', 'attackNearbyEnemy', 'say', 'bustDownDoor', 'wait', 'swapItems', 'isBigger', 'isSmaller', 'buildXY', 'pickUpFlag', 'cleave', 'throw', 'cast', 'heal', 'hide', 'manaBlast', 'warcry', 'resetCooldown', 'envenom', 'backstab', 'bash', 'powerUp', 'scattershot', 'jump', 'jumpTo', 'electrocute', 'summon', 'dash', 'throwPos', 'shield', 'hurl', 'stomp', 'devour']
      usedPlannableMethods = (method for method in plannableMethods when @owner[method])

    # Attach all Components to our owner which it doesn't already have.
    for [componentClass, componentConfig] in @components
      if componentClass.className is 'Builds' and @owner.buildables
        # Attach new buildables without duplicating Builds.
        additionalBuilds = new componentClass componentConfig ? {}
        @owner.addBuildable buildType, buildable for buildType, buildable of additionalBuilds._buildables
        continue
      if componentClass.className is 'Commands' and @owner.commandableTypes
        # Attach new commandable types and methods without duplicating Commands.
        @owner.commandableTypes = _.union(@owner.commandableTypes, componentConfig.commandableTypes or [])
        @owner.commandableMethods = _.union(@owner.commandableMethods, componentConfig.commandableMethods or [])
        continue
      if componentClass.className is 'Collects' and @owner.collect and not @owner.inventorySystem.ignoreItemGold
        # Add basic income and starting gold without re-attaching Collects.
        @owner.inventorySystem.addGoldForTeam @owner.team, componentConfig.startingGold, false if componentConfig.startingGold
        @owner.inventorySystem.teamGold[@owner.team].income += componentConfig.income if componentConfig.income
        continue
      continue if _.find @owner.components, (c2) -> c2[0] is componentClass
      continue if componentClass.className is 'Item'
      @owner.addComponents [componentClass, componentConfig]

    # TODO: unjank this when upgrading Plans
    if @owner.plan
      for plannableMethod in _.difference plannableMethods, usedPlannableMethods when @owner[plannableMethod]?
        @owner.plannifyMethod plannableMethod
      
    @moreProgrammableProperties ?= []
    @hiddenProgrammableProperties ?= []
    if @owner.isProgrammable
      # Add our programmableProperties to our owner.
      programmableProperties = _.union @programmableProperties, @moreProgrammableProperties, @hiddenProgrammableProperties
      for prop in programmableProperties when not (prop in @owner.programmableProperties)
        @owner.programmableProperties.push prop unless (prop in @moreProgrammableProperties) or (prop in @hiddenProgrammableProperties)
        api = if _.isFunction @owner[prop] then @owner.apiOwnMethods else @owner.apiProperties
        api.push prop unless (prop in @owner.apiMethods) or (prop in @owner.apiProperties) or (prop in @owner.apiOwnMethods)
      @owner.moreProgrammableProperties ?= []
      for prop in @moreProgrammableProperties when not (prop in @owner.moreProgrammableProperties)
        @owner.moreProgrammableProperties.push prop
      for prop in @hiddenProgrammableProperties when not (prop in @owner.extraProgrammableProperties)
        @owner.extraProgrammableProperties.push prop
      
      # Repair any mistaken assignment of undefined methods to apiProperties by moving to apiOwnMethods.
      for prop in @owner.apiProperties.slice() when _.isFunction @owner[prop]
        @owner.apiProperties = _.without @owner.apiProperties, prop
        @owner.apiOwnMethods.push prop

    @owner.hudProperties = _.union @owner.hudProperties, @extraHUDProperties ? []
    @owner.updateRegistration()
    
    @owner.postEquip?()

  modifyStats: ->
    return console.warn @id, "can't modify stats for ownerID", @ownerID, "because that owner doesn't exist." unless @owner
    for prop, modifiers of @stats
      @modifyStat prop, modifiers
      if /^max.+/.test(prop)  # If we did maxHealth, we should do health, too.
        relatedProp = prop.replace(/^max(.)(.*)/, (groups...) -> groups[1].toLowerCase() + groups[2])
        @modifyStat relatedProp, modifiers, prop if @owner[relatedProp]?
      if @owner[prop + 'Squared']  # If we did visualRange, we should do visualRangeSquared, too.
        @owner[prop + 'Squared'] = Math.pow @owner[prop], 2

  modifyStat: (prop, modifiers, originalProp=null) ->
    oldVal = @owner[prop]
    @owner[prop] = modifiers.setTo if modifiers.setTo?
    @owner[prop] += modifiers.addend * (@owner[(originalProp ? prop) + 'Factor'] or 1) if modifiers.addend? and @owner[prop]?
    @owner[prop] *= modifiers.factor if modifiers.factor?
    allProperties = (@owner.programmableProperties ? []).concat(@owner.moreProgrammableProperties ? []).concat @owner.hudProperties ? []
    if not _.isEqual(@owner[prop], oldVal) and ((prop in allProperties) or prop.substr(0, 3) is 'max')
      type = ''
      type ||= 'number' if _.isNumber @owner[prop]
      type ||= 'string' if _.isString @owner[prop]
      type ||= 'boolean' if @owner[prop] is false or @owner[prop] is true
      type ||= 'array' if _.isArray @owner[prop]
      type ||= 'object'
      @owner.addTrackedProperties [prop, type]
      @owner.keepTrackedProperty prop
    #console.log @owner.id, "set", prop, "from", oldVal, "to", @owner[prop], "because of", @id, "from modifiers", modifiers

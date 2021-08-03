Component = require 'lib/world/component'

module.exports = class RunnerArenaAPI extends Component
  @className: 'RunnerArenaAPI'
  # chooseAction: ->

  attach: (thang) ->
    super thang
    Object.defineProperty(thang, 'row', {
      get: () -> Math.floor((@pos.y - @offsetY) / @stepY),
      set: (x) => throw new Error("You can't set game.time")
    })
    # thang.addActions {name: 'attack', cooldown: 0.25, specificCooldown: 0}
    thang.addActions {name: 'power-up', cooldown: 0.5, specificCooldown: 0.25}
  
  findNearestInRow: (row) ->
    return null unless @row?
    return unless @world.movingThangs?.length
    row ?= @row
    nearest = null
    nearestDist = 9000
    for th in @world.movingThangs when th.exists and not th.used and th.row is row and th.offsetY is @offsetY and th.pos.x >= @offsetX
      d = th.pos.x - @pos.x
      # console.log("DDD", @world.age, @pos, th?.pos, d, nearestDist)
      if d < nearestDist
        nearest = th
        nearestDist = d
    
    return nearest
  
  findAllInRow: (row) ->
    return [] unless @row?
    return [] unless @world.movingThangs?.length
    row ?= @row
    thangs = (th for th in @world.movingThangs when th.exists and not th.used and th.row is row and th.offsetY is @offsetY and th.pos.x >= @offsetX)
    thangs.sort((a, b) => a.pos.x - b.pos.x)
    return thangs
  
  getMap: ->
    return null unless @row?
    return unless @world.movingThangs?.length?
    thangs = (th for th in @world.movingThangs when th.exists and not th.used and th.offsetY is @offsetY and th.pos.x >= @offsetX)
    fMap = ((null for x in [@offsetX..80] by @stepX) for row in [0..5])
    for th in thangs
      col = Math.floor((th.pos.x - @offsetX) / @stepX)
      fMap[th.row][col] = th
    return fMap
    
  getTypeMap: ->
    fMap = @getMap()
    return unless fMap
    return (((if th then th.type else "") for th in row) for row in fMap)
        
  
  # jump: ->
  #   @velocity.z = 16
  #   @jumped = true
  #   @block()?
  
  
  horizontalDistance: (thang) ->
    return null unless thang.exists and thang.pos.x >= @offsetX
    return (thang.pos.x - @pos.x) / @stepX
  
  verticalDistance: (thang) ->
    return null unless thang.exists
    return (thang.pos.y - @pos.y) / @stepY
  
  hit: ->
    @setAction "attack"
    @hasAttacked = true
    @act()
    @block()
  
  
  canUsePower: (powerName) ->
    return false unless @powerCosts[powerName]
    return @powerCosts[powerName] <= @hero.gold
  
  costOf: (powerName) ->
    return @powerCosts[powerName] or 9001
  
  usePower: (powerName, powerArg) ->
    cost = @powerCosts[powerName]
    return unless cost
    if powerName is "bomb-wall"
      @powerUsed = "bomb-wall"
    if powerName is "fire-wall"
      @powerUsed = "fire-wall"
    if powerName is "shield"
      @effects = (e for e in @effects when e.name isnt 'shield')
      @addEffect {name: 'shield', duration: @shieldDuration, reverts: true, targetProperty: 'isShielding', setTo: true}
    if powerName is "jump"
      if not powerArg? or isNaN(powerArg) or powerArg < 0 or powerArg > 5
        @sayWithoutBlocking("I need a second argument: an integer from 0 to 5")
        return
      @pos.y = @offsetY + powerArg * @stepY
      @keepTrackedProperty("pos")
    @world.getSystem("Inventory")?.subtractGoldForTeam(@team, cost)
    
  
    
    @hasUsedPower = true
    @setAction "power-up"
    @act()
    @block()
  
  # moveUp: ->
  #   @pos.y += @stepY
  #   @keepTrackedProperty("pos")
  #   # @setAction("move")
  #   @moved = true
  #   # console.log("MOVE", @world.age, @pos.y)
  #   return @block()?
  
  # moveDown: ->
  #   @pos.y -= @stepY
  #   @keepTrackedProperty("pos")
  #   # @setAction("move")
  #   @moved = true
  #   # console.log("MOVE", @world.age, @pos.y)
  #   return @block()?
  
  update: ->
    if @hasAttacked or @hasUsedPower
      @hasAttacked = false
      @hasUsedPower = false
      @unblock()
    if @jumped 
      if @isGrounded()
        @jumped = false
      # console.log("END", @world.age, @pos.y)
        @unblock?()
      if @pos.z >= 5
        @velocity.z = -9
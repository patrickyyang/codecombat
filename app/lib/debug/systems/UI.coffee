System = require 'lib/world/system'

module.exports = class UI extends System
  constructor: (world, config) ->
    super world, config
    @world.addTrackedProperties 'showCoordinates', 'showGrid', 'showPaths'
    @world.showCoordinates = @showCoordinates
    @world.showGrid = @showGrid
    @world.showPaths = @showPaths
    @world.keyArray = []
    @world.keyStack = []
    @world.realTimeInputEvents = []
    
  update: ->
    hash = 0

    for realTimeInputEvent in @world.realTimeInputEvents when realTimeInputEvent.time <= @world.age
      hash += @processRealTimeInputEvent realTimeInputEvent
    
    #if @world.keyStack.length
      #@world.player.trigger? "keyheld", @world.keyArray[@world.keyStack[@world.keyStack.length - 1]]

    for key in @world.keyStack
      @world.player?.trigger? "keyheld", @world.keyArray[key]
      if @world.gameReferee?.eventHandlers?.keyheld
          @world.gameReferee?.trigger? "keyheld", _.clone(@world.keyArray[key])
    
    @world.realTimeInputEvents = @world.realTimeInputEvents.filter((elem) -> return not elem.processed)
    
    return hash

  processRealTimeInputEvent: (event) ->
    return unless @world.player or @world.gameReferee
    # events have type ('mousedown'), pos, time, and thangID
    event.processed = true
    event.other = @world.getThangByID event.thangID
    #console.log event.time, event.type, event.pos?.x, event.pos?.y, event.thangID, event.other
    if event.keyCode
      event.keyChar = String.fromCharCode(event.keyCode)
    if event.type is 'mousedown'
      @world.player?.trigger? "click", event
      if @world.gameReferee?.eventHandlers?.click
          @world.gameReferee?.trigger? "click", _.clone(event)
    
    if event.type is 'keyup'
      @world.player?.trigger? 'keyup', event
      if @world.gameReferee?.eventHandlers?.keyup
          @world.gameReferee?.trigger? "keyup", _.clone(event)
      @world.keyArray[event.keyCode] = undefined
      @world.keyStack.splice(@world.keyStack.indexOf(event.keyCode), 1)
    
    if event.type is 'keydown' and @world.keyStack.indexOf(event.keyCode) is -1
      @world.player?.trigger? 'keydown', event
      if @world.gameReferee?.eventHandlers?.keydown
          @world.gameReferee?.trigger? "keydown", _.clone(event)
      @world.keyStack.push(event.keyCode)
      @world.keyArray[event.keyCode] = event
    
    if event.pos?.x and event.pos?.y
      hash = event.time + event.pos.x - event.pos.y
    else
      hash = event.time
    hash
    
  displayClick: (pos) ->
    return unless hero = @world.getThangByID "Hero Placeholder"
    radius = 1
    color = '#008FFF'
    startAngle = endAngle = 0
    args = [pos.x, pos.y, radius, color, endAngle, startAngle]
    hero.addCurrentEvent "aoe-#{JSON.stringify(args)}"

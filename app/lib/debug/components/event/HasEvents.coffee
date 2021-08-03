Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

module.exports = class HasEvents extends Component
  @className: "HasEvents"
  hasChangedCurrentEvents: false
  constructor: (options) ->
    super options
    @validEventTypes = ["spawn", "hear", "update", "click", "keydown", "keyup", "keyheld", "defeat", "collect", "collide", "victory", "exit"]
    @currentEvents = []
    @eventHandlers = {}
    @eventQueue = []
    @eventThreadAetherStack = []

  attach: (thang) ->
    super thang
    thang.addTrackedProperties ['currentEvents', 'array']

  addCurrentEvent: (event) ->
    # "currentEvents" are just strings, like 'take-damage'. That's a legacy API for sending some visualizable stuff to the Surface and triggering some scripts and goals.
    # Most of the events we care about *inside* the game engine are actual real event objects, with on/trigger/off and event handlers the player will write.
    @currentEvents.push event
    @keepTrackedProperty 'currentEvents'

  on: (eventType, handler) ->
    unless eventType in @validEventTypes
      throw new ArgumentError "The first argument should be one of [\"#{@validEventTypes.join('\", \"')}\"].", "on", "eventType", "string", eventType
    unless typeof(handler) is 'function'
      throw new ArgumentError "The second argument should be a function.", "on", "handler", "function", handler

    @eventHandlers[eventType] ?= []
    handler.triggerOneTimeOnly  = true if (eventType is "spawn" or (eventType is "update" and handler.inspect?))
    handler.timesTriggered ?= {}
    handler.timesTriggered[@id] = 0
    @eventHandlers[eventType].push(handler)

    if eventType is "spawn" and @didTriggerSpawnEvent
      @trigger "spawn"


  trigger: (eventType, eventData={}) ->
    # TODO: handle undefined/null, function
    @didTriggerSpawnEvent = true if eventType is "spawn"
    return unless handlers = @eventHandlers[eventType]
    toRemove = []
    for handler in handlers
      eventData.type = eventType
      eventData.target = @
      if handler.triggerOneTimeOnly and handler.timesTriggered[@id] >= 1
        toRemove.push handler
        continue
      handler.timesTriggered[@id] += 1
      @eventQueue.push data: eventData, handler: handler
    for handler in toRemove
      @off eventType, handler

  off: (eventType, handler=null) ->
    # TODO: handle undefined/null, function
    return unless handlers = @eventHandlers[eventType]
    if handler
      @eventHandlers[eventType] = (h for h in handlers when h isnt handler)
    else
      @eventHandlers[eventType] = []

  once: (eventType, handler) ->
    unless eventType in @validEventTypes
      throw new ArgumentError "The first argument should be one of [\"#{@validEventTypes.join('\", \"')}\"].", "on", "eventType", "string", eventType
    unless typeof(handler) is 'function'
      throw new ArgumentError "The second argument should be a function.", "on", "handler", "function", handler

    @eventHandlers[eventType] ?= []
    handler.triggerOneTimeOnly  = true
    handler.timesTriggered ?= {}
    handler.timesTriggered[@id] = 0
    @eventHandlers[eventType].push(handler)

    if eventType is "spawn" and @didTriggerSpawnEvent
      @trigger "spawn"
  
  findEventAether: ->
    # TODO: fix the jank. This maybe not work unless we are setting @commander, which we just decided wouldn't be a good idea for pets.
    return @world.userCodeMap['Hero Placeholder']?.plan unless @commander?.id? and @commander.id isnt 'Hero Placeholder'
    return @world.userCodeMap['Hero Placeholder 1']?.plan if @commander.id is 'Hero Placeholder 1'
    return null  # Some other commander?

  configureHandlerGenerator: (createHandlerGenerator, eventData) ->
    handlerGenerator = createHandlerGenerator(eventData)
    handlerGenerator.createHandlerGenerator = createHandlerGenerator
    handlerGenerator.originalEventData = eventData
    return handlerGenerator
  
  update: ->
    # TODO: at some point, if we made this happen after the plans() chooseAction, it would update the line-by-line highlighting in the editor.
    while @eventQueue?.length
      event = @eventQueue.shift()
      if event.handler.inspect?
        aether = @findEventAether()
        return unless aether
        handlerGenerator = @configureHandlerGenerator aether.createThread(event.handler), event.data
        @eventThreadAetherStack.unshift handlerGenerator
      else
        # handler is just a native function so we'll invoke it
        event.handler(event.data)
    @processNextEventThread()
    
  processNextEventThread: ->
    return unless @eventThreadAetherStack.length
    handlerGenerator = @eventThreadAetherStack[0]
    try
      {value, done} = handlerGenerator.next()
    catch error
      programmableThang = if @commander?.id is 'Hero Placeholder 1' then @commander else @world.getThangByID 'Hero Placeholder'
      if programmableThang
        programmableThang.handleProgrammingError error, 'plan'
      [value, done] = [null, true]
    if done
      # if it's an "update" handler, then reset the generator instead of dropping the thread
      # to avoid performance hit of creating so many new threads
      @eventThreadAetherStack.shift()
      result = @processNextEventThread()
      if handlerGenerator.originalEventData?.type is 'update'
        handlerGenerator = @configureHandlerGenerator handlerGenerator.createHandlerGenerator, handlerGenerator.originalEventData
        @eventThreadAetherStack.unshift handlerGenerator

      return result
    @eventThreadAetherStack[0]

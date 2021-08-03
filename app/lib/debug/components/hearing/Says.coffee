Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Says extends Component
  @className: 'Says'
  constructor: (config) ->
    super config
    @voiceRangeSquared = @voiceRange * @voiceRange
    if @cooldown
      @_sayAction = name: 'say', cooldown: @cooldown

  attach: (thang) ->
    super thang
    if thang.acts and @_sayAction
      thang.addActions @_sayAction
    thang.addTrackedProperties ["sayMessage", "string"], ["sayStartTime", "number"]

  say: (message, data, _excess) ->
    if not message?
      throw new ArgumentError "Say what?", "say", "message", "string", message
    if data? and not _.isObject data
      throw new ArgumentError "data should be an object, like {target: enemy, action: 'attack'}", "say", "data", "object", data
    if _excess?
      throw new ArgumentError '', 'say', "_excess", "", "", 1
    @sayWithDuration @actions.say?.cooldown ? 3.0, message, data ? {}
    
  sayWithoutBlocking: (message, duration) ->
    duration ?= @actions.say?.cooldown ? 3.0
    @preventSayBlocking = true
    @sayWithDuration duration, message
    @preventSayBlocking = false

  sayWithDuration: (duration, message, data) ->
    if not message? or message is ""
      return @clearSpeech()
    else if _.isEqual message, []
      message = "[]"
    else if _.isEqual message, {}
      message = "{}"
    else
      message = '' + message  # string it

    if @actions.say and not @preventSayBlocking
      @setAction "say"

    if @sayMessage is message and @sayData is data
      @sayRemainingAge = duration  # Refresh the duration while continue to say it
    else
      messagesAreSimilar = false  # Determine whether this should play a sound as a separate utterance
      if @sayMessage
        if @sayMessage.split(' ')[0] == message.split(' ')[0]
          messagesAreSimilar = true
        else if string_score.score(message, @sayMessage, 0.5) > 0.25
          messagesAreSimilar = true
        #console.log @id, "Messages are similar?", messagesAreSimilar, @sayMessage, message, @sayMessage.split(' ')[0], message.split(' ')[0], string_score.score(message, @sayMessage, 0.5)
      sayStartTime = if messagesAreSimilar then @sayStartTime else @world.age
      @clearSpeech()
      @sayMessage = message
      @sayData = data
      @sayStartTime = sayStartTime
      @sayDuration = duration
      @sayRemainingAge = duration
      @sayStartPos = @pos.copy()
      @keepTrackedProperty 'sayMessage'
      @keepTrackedProperty 'sayStartTime'
      
    if @actions.say and not @preventSayBlocking
      @brake?()  # Added 2016-05-18 since we basically always want braking when the hero talks.
      return @block?()

  clearSpeech: ->
    @sayHeardBy = {}
    @sayMessage = @sayData = @sayStartTime = @sayRemainingAge = @sayDuration = @sayStartPos = null

  update: ->
    # If we are blocked saying something, unblock one frame before the hearing system would clear it (matching old yielding behavior)
    return unless @action is 'say' and @world.age - @sayStartTime >= @actions.say?.cooldown - @world.dt
    @clearSpeech()
    @setAction 'idle'
    @unblock?()
  
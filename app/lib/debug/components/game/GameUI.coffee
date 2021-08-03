Component = require 'lib/world/component'

module.exports = class GameUI extends Component
  @className: 'GameUI'
  
  initialize: ->
    # This stuff makes the esper_property thing work properly.
    return unless aether = @world.userCodeMap['Hero Placeholder']?.plan  # TODO: fix the jank
    esperEngine = aether.esperEngine
    if not @world.uiText
      @world.uiText = {directions: []}

    @ui = { track: @ui_track, setText: @ui_setText, _self: @ }
    esperEngine.addGlobal 'ui', @ui
    
    esper.SmartLinkValue.makeThreadPrivileged esperEngine.evaluator
  
  
  #### UI Stuff
  ui_track: (object, key) ->
    # TODO: Probably some clean up and argument errors
    ### !!! Beware all who enter !!!
      In order to get this information pumped out of the level, we make sure to track the values we want access to inside GameDevTrackView
      Players can track the key inside of a Thang, the key instead of an object, or a normal datatype (string, number). They cannot track arrays (left as homework for the viewer)
      If it is a Thang, the Thang itself keeps track of what needs to be displayed on the UI and spits that through the "trackedProperties" channel.
      If it is an object or normal datatype, the mcp has to store it, so it creates a special area to store the names of these ui trackable properties and does some defineProperty magic to ensure whole objects aren't being serialized to the UI.
    ###
    if object instanceof Thang
      unless object.uiTrackedProperties # If the object doesn't have an array of uiTrackableProperties, set one up
        object.uiTrackedProperties = []
        object.addTrackedProperties ["uiTrackedProperties", "array"]
        object.keepTrackedProperty "uiTrackedProperties"
      if not object.trackedPropertiesKeys? or object.trackedPropertiesKeys.indexOf(key) is -1 # If the object isn't already tracking key
        if typeof object[key] is "undefined"
          object[key] = 0
        object.addTrackedProperties [key, (typeof object[key]).toLowerCase()]
        object.keepTrackedProperty key
      if object.uiTrackedProperties.indexOf(key) is -1 # If the key is new, push it
        object.uiTrackedProperties.push key
    else
      unless @_self.objTrackedProperties
        @_self.objTrackedProperties = []
        @_self.addTrackedProperties ["objTrackedProperties", "array"]
        @_self.keepTrackedProperty "objTrackedProperties"
      if not @_self.trackedPropertiesKeys? or @_self.trackedPropertiesKeys.indexOf("__" + key) is -1 # If the object isn't already tracking key
        if typeof object is "object"
          if object.get? and object.add? # Probably the db object
            Object.defineProperty(@_self, "__" + key, { # Okay, so: We're tracking an object which may be circular, so instead of tracking the object directly, we create a getter at the place it should be to only retrieve what we want.
              get: () ->
                return object.get(key) ? 0;
            })
          else # Probably not the db object
            Object.defineProperty(@_self, "__" + key, {
              get: () ->
                return object[key]
            })
        else
          @_self["__" + key] = object
        @_self.addTrackedProperties ["__" + key, (typeof @_self["__" + key]).toLowerCase()]
        @_self.keepTrackedProperty "__" + key
      if @_self.objTrackedProperties.indexOf(key) is -1 # If the key is new, push it
        @_self.objTrackedProperties.push key

  # Allows user to set various front end elements in the game dev environment.
  # Preconditions:
  #   - label must be a recognized string.
  #   - Both label and value must be a string.
  # `value` can be an empty string.
  ui_setText: (label, value) ->
    return unless typeof label is "string" and typeof value is "string"
    supportedLabels = ["directions", "scoreLabel", "levelName", "victoryMessage"]
    if label not in supportedLabels
      # TODO: Make this error message nicer.
      throw new Error ("Don't recognize the label '#{label}'. Use one of: #{supportedLabels}")
    return unless label in supportedLabels
    if label is "directions"
      @_self.world.uiText[label].push(value)
    else if label in ["scoreLabel", "levelName", "victoryMessage"]
      @_self.world.uiText[label] = value

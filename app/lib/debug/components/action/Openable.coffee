Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'
MAX_COOLDOWN = require 'lib/world/systems/action'

module.exports = class Openable extends Component
  @className: 'Openable'
  OPEN: "open"
  CLOSE: "close"
  
  attach: (thang) ->
    super thang
    for act, name of @actionNames when name
      thang.addActions name: name, cooldown: 1
    thang.isOpen = false
  
  openOrClose: (prefix, fullOrEmpty) ->
    action = null
    if fullOrEmpty is undefined
      actionName = prefix + "Default"
    else if fullOrEmpty
      actionName = prefix + "Full"
    else
      actionName = prefix + "Empty"
    action = @actionNames[actionName]
    if action
      @setAction action
      @act()
    else
      throw new ArgumentError "#{@id} doesn't have an action for \"#{actionName}\"", prefix, "fullOrEmpty", "boolean"
    if @isDoor
      if prefix is @OPEN
        @cancelCollisions()
      else if prefix is @CLOSE
        @restoreCollisions()
  
  open: (fullOrEmpty) ->
    return if @isOpen
    @openOrClose @OPEN, fullOrEmpty
    @isOpen = true
  
  close: (fullOrEmpty) ->
    return unless @isOpen
    @openOrClose @CLOSE, fullOrEmpty
    @isOpen = false

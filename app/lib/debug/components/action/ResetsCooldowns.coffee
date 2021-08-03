Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

module.exports = class ResetsCooldowns extends Component
  @className: 'ResetsCooldowns'

  attach: (thang) ->
    resetCooldownAction = name: 'reset-cooldown', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions resetCooldownAction

  resetCooldown: (action) ->
    actionKeys = _.keys(@actions)
    actionKeys = actionKeys.concat spellKeys if @spells and spellKeys = _.keys(@spells)
    unless _.isString action
      throw new ArgumentError "resetCooldown takes a string action; one of [#{actionKeys.join(', ')}]", "resetCooldown", "action", "string", action
    unless action in actionKeys
      throw new ArgumentError "You don't have action \"#{action}\", only [#{actionKeys.join(', ')}]", "resetCooldown", "action", "string", action
    @setAction 'reset-cooldown'  
    @actionToReset = action
    if @getCooldown('reset-cooldown') > 1
      "done"
    else if @resetCooldownOnce
      @resetCooldownOnce = false
      @setAction 'idle'
      "done"
    else
      "reset-cooldown"

  update: ->
    return unless @action is 'reset-cooldown' and @act()
    @actionHeats[@actionToReset] = 0 if @actionHeats[@actionToReset]
    @spellHeats[@actionToReset] = 0 if @spellHeats?[@actionToReset]
    @resetCooldownOnce = true if @plan

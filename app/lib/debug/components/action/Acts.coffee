Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Acts extends Component
  @className: 'Acts'
  acts: true
  actionActivated: false
  action: 'idle'
  # meaningless change to acts
  attach: (thang) ->
    super thang
    thang.actionHeats = all: 0
    thang.actionTimeFactor = 1
    thang.addActions name: 'idle', cooldown: 0
    thang.setAction 'idle' unless thang.action
    thang.addTrackedProperties ['action', 'string'], ['actionActivated', 'boolean']

  chooseAction: ->
    # Other Components override this and call setAction here.

  setAction: (action) ->
    if typeof action is 'undefined'
      throw new ArgumentError "You need an action to perform.", "setAction", "action", "string", action
    action ?= 'idle'
    unless _.isString action
      throw new ArgumentError "You need a string action; one of [#{_.keys(@actions).join(', ')}]", "setAction", "action", "string", action
    unless action of @actions
      throw new ArgumentError "You don't have action \"#{action}\", only [#{_.keys(@actions).join(', ')}]", "setAction", "action", "string", action
    action = 'die' if @dead
    if action isnt @action
      @keepTrackedProperty 'action'
      @action = action
    if @isProgrammable and @actionsChosenThisCall? and aether = @getAetherForMethod 'chooseAction'
        statementRange = aether.lastStatementRange
        if ++@actionsChosenThisCall is 1
          @firstActionStatementRange = statementRange
        else if @actionsChosenThisCall < 20
          if @actionsChosenThisCall is 2
            actionRanges = [@firstActionStatementRange, statementRange]
          else
            actionRanges = [statementRange]
          for actionRange in actionRanges
            message = "Only the last action set in chooseAction() will be applied."
            fakeError = {name: "OverwroteAction", message: message, toString: -> message}
            problem = aether.createUserCodeProblem type: 'runtime', level: 'info', error: fakeError, range: actionRange
            @addAetherProblemForMethod problem, 'chooseAction'
    @action

  addActions: (actions...) ->
    # Add actions with their cooldowns like this: @addAction {name: 'move', cooldown: 0}, {name: 'attack', cooldown: 1.0}, {name: 'burninate', cooldown: 1.0, specificCooldown: 10}
    @actions ?= {}
    (@actions[action.name] = action) for action in actions

  act: (force=false) ->
    # Apply the cooldowns needed to perform the current action, or return false if not ready (and not forced)
    return false if (@actionHeats.all > 0 or @actionHeats[@action] > 0) and not force
    action = @actions[@action]
    if not @actionActivated and @action isnt 'idle' and (action.cooldown or @action isnt @previousAction)
      @actionActivated = true  # action has activated (changed significantly) this frame
      @keepTrackedProperty 'actionActivated'
    @actionHeats.all = action.cooldown if action.cooldown
    @actionHeats[@action] = action.specificCooldown if action.specificCooldown
    @previousAction = @action
    true

  canAct: (action=null) ->
    return false if @actionHeats.all
    return false if action and @actionHeats[@action]
    true

  getActionName: ->
    return @action ? "idle"
    
  getCooldown: (action) ->
    if @spellHeats?[action]
      return Math.max(@spellHeats[action] ? 0, @actionHeats.all)
    if @actionHeats[action]
      return Math.max(@actionHeats[action] ? 0, @actionHeats.all)
    return 0
    
  findCooldown: (action) ->
    unless _.isString action
      throw new ArgumentError "findCooldown needs a string action; one of [#{_.keys(@actions).join(', ')}]", "findCooldown", "action", "string", action
    unless action of @actions
      throw new ArgumentError "You don't have action \"#{action}\", only [#{_.keys(@actions).join(', ')}]", "findCooldown", "action", "string", action
    @getCooldown action    

  isReady: (action) ->
    actionKeys = _.keys(@actions)
    actionKeys = actionKeys.concat spellKeys if @spells and spellKeys = _.keys(@spells)
    
    unless _.isString action
      #throw new ArgumentError "isReady takes a string action; one of [#{_.keys(@actions).join(', ')}]", "isReady", "action", "string", action
      throw new ArgumentError "isReady takes a string action; one of [#{actionKeys.join(', ')}]", "isReady", "action", "string", action
    unless action in actionKeys
      [closestScore, message] = [0, '']
      for otherAction in actionKeys
        matchScore = otherAction.score action, 0.8
        [closestScore, message] = [matchScore, "The action is \"#{otherAction}\", not \"#{action}\"."] if matchScore > closestScore
      if closestScore >= 0.5
        throw new ArgumentError message, "isReady", "action", "string", action
      return false  # http://discourse.codecombat.com/t/cleave-x-powerup-and-isready-function/2427/4
      #throw new ArgumentError "You don't have action \"#{action}\", only [#{actionKeys.join(', ')}]", "isReady", "action", "string", action
    
    not @getCooldown action
    
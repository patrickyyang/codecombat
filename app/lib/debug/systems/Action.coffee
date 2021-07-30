System = require 'lib/world/system'
{MAX_COOLDOWN} = require 'lib/world/systems/action'

# Ideally the Action System runs after any Systems that might determine the current action and before any Systems that might make use of the current action.
# The Programming and AI Systems would determine the action.
# The UI, Collision, Movement, Targeting, Combat, Vision, Hearing, and Inventory Systems would depend on it.
# Those Systems might also force us to 'idle' or 'die', though, too. I guess this will work.

module.exports = class Action extends System
  constructor: (world, config) ->
    super world, config
    @actors = @addRegistry (thang) -> thang.exists and thang.acts
    @priorityActors = []
    
  update: ->
    @detectLevelType() unless @levelType
    hash = 0
    actors = @actors.slice()  # avoid changing during iteration
    for actor in @priorityActors
      hash += @playActor actor
    for actor in actors when actor not in @priorityActors
      hash += @playActor actor
    hash
  
  playActor: (actor) ->
    hash = 0
    dt = @world.dt * (actor.actionTimeFactor or 1)
    if actor.actionActivating
      # We should deactivate, but because the action was activated at the wrong time in the frame, we have to wait a frame.
      actor.actionActivating = false
    else if actor.actionActivated
      actor.actionActivated = false
    if actor.actionHeats.all < MAX_COOLDOWN
      for action, heat of actor.actionHeats
        useActionTimeFactor = action isnt 'all'
        actor.actionHeats[action] = Math.max 0, heat - (if useActionTimeFactor then dt else @world.dt)
      if actor.actionHeats.all is 0
        actor.setAction 'idle' if actor.resetsToIdle
        actor.chooseAction() unless actor.dead
        hash += @world.age * @hashString(actor.id + actor.action)
    hash
  
  detectLevelType: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    @hero2 = @world.getThangByID 'Hero Placeholder 1'
    for [componentClass, componentConfig] in @hero.components
      if componentClass.className is 'GameReferee'
        @levelType = 'game-dev'
        break
      if componentClass.className in ['UsesHTML', 'UsesJquery']
        @levelType = 'web-dev'
        break
    @levelType = @levelType || 'hero'
    if @levelType in ['web-dev', 'game-dev']
      @priorityActors.push @hero
    for thang in @world.thangs
      for [componentClass, componentConfig] in thang.components
        if componentClass.className.search('Referee') isnt -1
          @priorityActors.push thang unless thang in @priorityActors
    if @levelType is 'hero'
      @priorityActors.push @hero
      @priorityActors.push(@hero2) if @hero2
      @priorityActors.push(@hero.pet) if @hero.pet
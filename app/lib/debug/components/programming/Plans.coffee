Component = require 'lib/world/component'

# Attach this after other components are attached
module.exports = class Plans extends Component
  plannifiedMethodsActive: false  # We will only do special yielding for plannified methods that are called as part of a chooseAction
  @className: 'Plans'
  attach: (thang) ->
    @planIterations = 0
    @planWorldEndsAfter = @worldEndsAfter
    delete @worldEndsAfter
    super thang
    # TODO: unjank the copy of this in Item when upgrading Plans; until then, add things both places.
    for plannableMethod in ['pickUpItem', 'dropItem', 'push', 'move', 'moveXY', 'follow', 'moveRight', 'moveLeft', 'moveUp', 'moveDown', 'attack', 'attackPos', 'attackXY', 'attackNearestEnemy', 'attackNearbyEnemy', 'say', 'bustDownDoor', 'wait', 'swapItems', 'isBigger', 'isSmaller', 'buildXY', 'pickUpFlag', 'cleave', 'throw', 'cast', 'heal', 'hide', 'manaBlast', 'warcry', 'resetCooldown', 'envenom', 'backstab', 'bash', 'powerUp', 'scattershot', 'jump', 'jumpTo', 'electrocute', 'summon', 'dash', 'throwPos', 'shield', 'hurl', 'stomp', 'devour']
      if thang[plannableMethod]?
        thang.plannifyMethod plannableMethod
  
  plannifyMethod: (methodName) ->
    # plannableMethods should return either an action or 'done'
    if methodName is 'say' and not @actions.say
      # if it wasn't blocking, we need to make it block at least a moment or it won't work
      @addActions name: 'say', cooldown: 1
      
    originalMethod = @[methodName]
    @[methodName] = (args...) =>
      aether = @getAetherForMethod 'plan'
      try
        action = originalMethod.apply @, args
      catch error
        @handleProgrammingError error, 'plan'
        @replaceMethodCode 'plan', null  # no-op when this method is called
      #console.log @id, 'returning', action, 'at time', @world.age, 'because we are not in plan()' unless @plannifiedMethodsActive
      return action unless @plannifiedMethodsActive  # Don't yield if, for example, we are calling this method from engine code and not player code
      
      if action isnt "done"
        @currentPlan = methodName: methodName, methodArgs: args
        return @future if @future?
        FutureValue = esper.FutureValue  # IE14 had troubles calling (esper.FutureValue())
        @future = new FutureValue()
        @future.oldStyle = true
        return @future
      return action

  plan: ->

  chooseAction: ->
    return @setAction "idle" if (@plansAreFinished or not @programmableMethods?.plan) and not @eventThreadAether
    aether = @getAetherForMethod 'plan'
    unless @planGenerator
      return @finishPlans() unless @planGenerator = @plan()
      aether.sandboxGenerator? @planGenerator
    if @currentPlan
      # Simple loops yield automatically without returning a continuation method
      if @future and not @future.oldStyle
        # We just wait for it to resolve and don't do anything here.
        #console.log 'Awaiting the new-style future to resolve, not pumping our plannified method ' + @currentPlan.methodName
        null
      else if @currentPlanMethodResolved
        @currentPlanMethodResolved = false
        @endCurrentPlan aether
      else
        # We pump our old-style repeatable plannified method to see if it's done
        @plannifiedMethodsActive = true
        action = if @currentPlan.methodName then @[@currentPlan.methodName](@currentPlan.methodArgs...) else "done"
        @plannifiedMethodsActive = false
        if action is "done"
          if @future?
            @future.resolve(esper.Value.fromNative('done'))
            @future = undefined
          @endCurrentPlan aether
    else
      @_aetherUserInfo.time = aether._userInfo.time = @world.age
      ++@_aetherAPIOwnMethodsAllowed
      try
        @plannifiedMethodsActive = true
        {value, done} = @planGenerator.next()
        @plannifiedMethodsActive = false
      catch error
        @handleProgrammingError error, "plan"
        [value, done] = [null, true]
      --@_aetherAPIOwnMethodsAllowed
      if done
        @setAction 'idle'
        @intent = undefined
        if @planLoops
          @planGenerator = null
          @planIterations++
        else
          @finishPlans()
        
  endCurrentPlan: (aether) ->
    aether ?= @getAetherForMethod 'plan'
    @currentPlan = null
    @chooseAction()

  finishPlans: ->
    @publishNote 'thang-finished-plans', {}
    @velocity?.multiply(0) if @isGrounded?()  # Stop!
    @world.endWorld false, @planWorldEndsAfter, true if @planWorldEndsAfter
    @plansAreFinished = true

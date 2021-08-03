Component = require 'lib/world/component'

module.exports = class HasEffects extends Component
  @className: "HasEffects"
  
  attach: (thang) ->
    super thang
    thang.effects = []
    thang.effectNames = []
    thang.addTrackedProperties ['effectNames', 'array']
    thang.hasEffects = true
    thang.basePropertyValues = {}
    thang.effectSystem = thang.world.getSystem('Effect')
    #if thang.effectSystem
      #thang.addEffect({
        #name: 'poison'
        #addend: -10
        #targetProperty: 'health'
        #reverts: true
        #duration: 15
      #})

  addEffect: (effect) ->
    return unless @[effect.targetProperty] isnt undefined or effect.setTo
    effect = _.clone effect
    effect.timeSinceStart ?= 0 if effect.duration
    effect.timeSinceRepeat ?= 0 if effect.repeatsEvery
    name = "effect-begin:#{effect.name}"
    @addCurrentEvent(name) unless name in @currentEvents
    
    if effect.reverts or effect.repeatsEvery or effect.duration
      @effects.push effect
      @updateRegistration()

    # If you use effect.reverts, don't use any other component or system to modify the property, or those changes will be wiped.
    if effect.reverts
      @basePropertyValues[effect.targetProperty] ?= @[effect.targetProperty] if effect.reverts
      @updateProperty effect.targetProperty
    else
      @applyEffect effect
    @updateEffectNames()
    @keepTrackedProperty 'effectNames'
    res = @keepTrackedProperty effect.targetProperty

  updateEffectNames: -> 
    @effectNames = _.uniq((e.name for e in @effects))

  applyEffect: (effect) ->
    # for effects that do not revert, apply the change directly
    value = @[effect.targetProperty]
    @[effect.targetProperty] = @operate(value, [effect])

  updateProperty: (targetProperty) ->
    # for effects that revert
    effects = (e for e in @effects when e.targetProperty is targetProperty)
    value = @basePropertyValues[targetProperty]
    @[targetProperty] = @operate(value, effects)

  operate: (value, effects) ->
    value = effect.setTo for effect in effects when effect.setTo?
    for effect in effects when effect.addend
      # TODO: Refactor to use takeDamage
      if effect.addend < 0 and effect.targetProperty is 'health'
        value += effect.addend * @damageMitigationFactor  # Shielding should prevent from effect damage
      else
        value += effect.addend
    value *= effect.factor for effect in effects when effect.factor?
    value
    
  updateEffects: (specificEffectName=null) ->
    # If specificEffectName is specified, only updates effects with that name
    delta = @world.dt
    propertiesToUpdate = []
    endingEffects = []
    effects = @effects.slice()
    for effect in effects
      continue if specificEffectName and effect.name isnt specificEffectName
      if effect.repeatsEvery and (not @dead or effect.targetProperty is 'alpha')
        effect.timeSinceRepeat += delta
        while effect.repeatsEvery < effect.timeSinceRepeat
          @applyEffect(effect)
          effect.timeSinceRepeat -= effect.repeatsEvery
          
      if effect.duration
        effect.timeSinceStart += delta
        if effect.duration < effect.timeSinceStart or (@dead and effect.targetProperty isnt 'alpha')
          effect.onRevert?()
          propertiesToUpdate.push effect.targetProperty if effect.reverts
          endingEffects.push effect.name
          @undoEffectProportionally effect if effect.revertsProportionally
          index = @effects.indexOf effect
          @effects.splice index, 1

    @updateProperty property for property in _.uniq propertiesToUpdate
    @addCurrentEvent "effect-end:#{effect}" for effect in _.uniq endingEffects
    @updateEffectNames() if endingEffects.length
    
    @updateRegistration() unless @effects.length

  hasEffect: (name) ->
    Boolean _.find @effects, name: name
    
  undoEffectProportionally: (effect) ->
    original = @[effect.targetProperty]
    undoEffect = {}
    undoEffect.addend = -effect.addend if effect.addend
    undoEffect.factor = 1 / effect.factor if effect.factor
    @[effect.targetProperty] = @operate(@[effect.targetProperty], [undoEffect])

  ###
  Things not handled because I couldn't think of good use cases for them:
  
  * mixing effects that do and do not revert for the same property
  * other systems or components changing properties with effects that revert
  * revert and repeatsEvery playing nice with one another
  ###

  ###
  @effectSchema =
    type: 'object'
    additionalProperties: false
    properties:
      name:
        type: 'string'
        description: 'Human readable name of the effect.'
      duration:
        type: 'number'
        description: 'Time in seconds that the effect lasts.'
      repeatsEvery:
        type: 'number'
        description: 'Repeats the effect every x seconds.'
      reverts:
        type: 'boolean'
        description: 'Property change goes back once the effect ends.'
      revertsProportionally:
        type: 'boolean'
        description: 'Property may change over time by outside forces.
          Recalculate when effect is over, reversing the calculation.
          So if factor is 0.5, initial value is 100, value goes to 50,
          then decreases by outside forces to 40, revert goes to 80
          instead of 100. This is mainly for health effects.'
      onRevert:
        type: 'function'
        description: 'Called when the effect ends, right before it reverts.'
      targetProperty:
        type: 'string'
        description: 'Property being affected.'
      setTo:
        description: 'Sets the property to this value.'
      addend:
        type: 'number'
        description: 'Adds to the property value (after setTo).'
      factor:
        type: 'number'
        description: 'Multiplies the property by the value (after setTo and any addends).'
  ###
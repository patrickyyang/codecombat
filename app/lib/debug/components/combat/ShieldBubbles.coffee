Component = require 'lib/world/component'

module.exports = class Shields extends Component
  @className: "Shields"

  constructor: (config) ->
    super config
    @shieldDefensePercent = parseInt(@shieldDefenseFactor * 100) # for property docs

    @shieldBubbleRangeSquared = @shieldBubbleRange * @shieldBubbleRange

  attach: (thang) ->
    shieldBubbleAction = name: 'shieldBubble', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions shieldBubbleAction

  shieldBubble: ->
    oldAction = @action
    @setAction 'shieldBubble'
    if @act()
      @startShieldBubbling()
      if oldAction is 'shieldBubble'
        @actionActivated = false
    else
      @intent = 'shieldBubble'
    return @block?() unless @commander?

  update: ->
    return unless @intent is 'shieldBubble' and @act()
    @startShielding()

  startShieldBubbling: ->
    @intent = undefined

    for friend in [].concat(@getFriends()) when friend.hasEffects and @distanceSquared(friend) <= @shieldBubbleRangeSquared
      friend.effects = (e for e in friend.effects when e.name isnt 'shield')
      effects = [
        {name: 'shield', duration: @actions['shieldBubble'].cooldown + @world.dt, reverts: true, factor: (1 - @shieldDefenseFactor * @shieldBubbleReductionFactor), targetProperty: 'damageMitigationFactor'}
      ]
      friend.addEffect effect, @ for effect in effects

    @effects = (e for e in @effects when e.name isnt 'shield')
    @addEffect {name: 'shielding', duration: @actions['shieldBubble'].cooldown, reverts: true, targetProperty: 'isShielding', setTo: true, onRevert: => @stopShielding()}

    if @heroIsShieldBubbled
      @addEffect {name: 'shield', duration: @actions['shieldBubble'].cooldown + @world.dt, reverts: true, targetProperty: 'damageMitigationFactor', factor: (1 - @shieldDefenseFactor * @shieldBubbleReductionFactor)}
    @brake?() if @isGrounded?()

    args = [parseFloat(@pos.x.toFixed(2)),parseFloat(@pos.y.toFixed(2)),parseFloat(@shieldBubbleRange.toFixed(2)),'#996600']
    @addCurrentEvent "aoe-#{JSON.stringify(args)}"


  stopShielding: ->
    @unblock()

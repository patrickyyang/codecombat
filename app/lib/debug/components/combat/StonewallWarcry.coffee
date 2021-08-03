Component = require 'lib/world/component'

module.exports = class StonewallWarcry extends Component
  @className: 'StonewallWarcry'

  constructor: (config) ->
    super config
    @warcryRangeSquared = @warcryRange * @warcryRange
    
  attach: (thang) ->
    warcryAction = name: 'warcry', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions warcryAction

  warcry: ->
    @setAction 'warcry'
    return @block?()

  update: ->
    return unless @action is 'warcry' and @act()
    @unblock?()
    @unhide?() if @hidden
    @addCurrentEvent? 'warcry'
    @sayWithoutBlocking? "Push them back!"
    # TODO: should only affect soldiers? other melee type units?
    for friend in [@].concat(@getFriends()) when friend.hasEffects and @distanceSquared(friend) <= @warcryRangeSquared
      friend.effects = (e for e in friend.effects when e.name isnt 'warcry')
      baseMass = Math.max(@warcryMinimumMass,friend.attackMass)
      effects = [
        {name: 'warcry', duration: @warcryDuration, reverts: true, setTo: 0.05, targetProperty: 'attackZAngle'}
        {name: 'warcry', duration: @warcryDuration, reverts: true, setTo: baseMass, targetProperty: 'attackMass'}
        {name: 'warcry', duration: @warcryDuration, reverts: true, factor: @warcryMassFactor, targetProperty: 'attackMass'}
      ]
      friend.addEffect effect, @ for effect in effects
    args = [parseFloat(@pos.x.toFixed(2)),parseFloat(@pos.y.toFixed(2)),parseFloat(@warcryRange.toFixed(2)),'#FF8C00']
    @addCurrentEvent "aoe-#{JSON.stringify(args)}"
    
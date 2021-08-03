Component = require 'lib/world/component'

module.exports = class WarCries extends Component
  @className: "WarCries"
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
    return @block?() unless @commander?

  update: ->
    return unless @action is 'warcry' and @act()
    @unblock?()
    @unhide?() if @hidden
    @addCurrentEvent? 'warcry'
    @sayWithoutBlocking? "Goooo #{@team}!"
    for friend in [@].concat(@getFriends()) when friend.hasEffects and @distanceSquared(friend) <= @warcryRangeSquared
      friend.effects = (e for e in friend.effects when e.name isnt 'warcry')
      effects = [
        {name: 'warcry', duration: @warcryDuration, reverts: true, factor: @warcryHasteFactor, targetProperty: 'maxSpeed'}
        {name: 'warcry', duration: @warcryDuration, reverts: true, factor: @warcryHasteFactor, targetProperty: 'actionTimeFactor'}
      ]
      friend.addEffect effect, @ for effect in effects
    args = [parseFloat(@pos.x.toFixed(2)),parseFloat(@pos.y.toFixed(2)),parseFloat(@warcryRange.toFixed(2)),'#FF8C00']
    @addCurrentEvent "aoe-#{JSON.stringify(args)}"

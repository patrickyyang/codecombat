Component = require 'lib/world/component'

module.exports = class Berserks extends Component
  @className: 'Berserks'

  attach: (thang) ->
    berserkAction = name: 'berserk', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions berserkAction

  berserk: ->
    @setAction 'berserk'
    return @block()

  update: ->
    if @action is 'berserk' and @act()
      @unblock()
      @actions['attack'].cooldown /= @berserkFactor
      
      berserkEffects = [
        {name: 'berserk', duration: @berserkDuration, reverts: true, setTo: true, targetProperty: 'isBerserk', onRevert: => @stopBerserking()}
      ]
      
      @addEffect effect for effect in berserkEffects

  stopBerserking: ->
    @actions['attack'].cooldown *= @berserkFactor

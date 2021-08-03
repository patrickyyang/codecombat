Component = require 'lib/world/component'

module.exports = class Shields extends Component
  @className: "Shields"

  constructor: (config) ->
    super config
    @shieldDefensePercent = parseInt(@shieldDefenseFactor * 100) # for property docs

  attach: (thang) ->
    shieldAction = name: 'shield', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions shieldAction

  shield: ->
    oldAction = @action
    @setAction 'shield'
    if @act()
      @startShielding()
      if oldAction is 'shield'
        @actionActivated = false
    else
      @intent = 'shield'
    return @block?() unless @commander?

  update: ->
    return unless @intent is 'shield' and @act()
    @startShielding()
  
  startShielding: ->
    @intent = undefined
    @effects = (e for e in @effects when e.name isnt 'shield')
    @addEffect {name: 'shield', duration: @actions['shield'].cooldown, reverts: true, targetProperty: 'isShielding', setTo: true, onRevert: => @stopShielding()}
    @addEffect {name: 'shield', duration: @actions['shield'].cooldown + @world.dt, reverts: true, targetProperty: 'damageMitigationFactor', factor: (1 - @shieldDefenseFactor)}
    @brake?() if @isGrounded?()
      
  
  stopShielding: ->
    @unblock()
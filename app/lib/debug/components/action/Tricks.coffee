Component = require 'lib/world/component'

module.exports = class Tricks extends Component
  @className: 'Tricks'
  attach: (thang) ->
    trickAction = name: 'trick', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions trickAction
  
  trick: () ->
    @setAction 'trick'
    @block?()
  
  update: () ->
    if @action is "trick" and @act()
      @unblock?()
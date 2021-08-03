Component = require 'lib/world/component'

module.exports = class CastsSwap extends Component
  @className: 'CastsSwap'

  constructor: (config) ->
    super config
    @_swapSpell = name: 'swap', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_swapSpell
  
  castSwap: (target) ->
    @cast 'swap', target, 'castSwap'

  perform_swap: ->
    spot = @target.pos
    @target.pos = @pos
    @pos = spot
    @target.pos.z = Math.max 0, @target.depth / 2
    @pos.z = Math.max 0, @depth / 2
    @hasMoved = true
    @target.hasMoved = true

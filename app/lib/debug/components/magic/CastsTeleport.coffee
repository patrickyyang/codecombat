Component = require 'lib/world/component'

module.exports = class CastsTeleport extends Component
  @className: 'CastsTeleport'

  constructor: (config) ->
    super config
    @_teleportSpell = name: 'teleport', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_teleportSpell
    
  castTeleport: (target) ->
    @cast 'teleport', target, 'castTeleport'

  perform_teleport: ->
    pos = @targetPos or @target.pos or @target
    until @isPathClear @pos, pos
      distance = pos.distance(@pos)
      return unless distance > 2
      pos = pos.copy().subtract(@pos).limit distance - 1
    
    @pos.x = pos.x
    @pos.y = pos.y
    @pos.z = Math.max pos.z, @depth / 2
    @pos.z = Math.min pos.z, @spells.teleport.range
    @hasMoved = true
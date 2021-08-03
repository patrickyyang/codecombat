Component = require 'lib/world/component'

Vector = require 'lib/world/vector'
{ArgumentError} = require 'lib/world/errors'

module.exports = class Teleports extends Component
  @className: "Teleports"

  constructor: (config) ->
    super config
    if @cooldown
      @_teleportAction = name: 'teleport', cooldown: @cooldown
    delete @cooldown

  attach: (thang) ->
    super thang
    if thang.acts and @_teleportAction
      thang.addActions @_teleportAction
    if thang.teleportsInitially
      thang.teleportRandom()

  teleportRandom: ->
    return console.log "Couldn't teleport randomly, no teleportBoundary!" unless @teleportBoundary
    x = @world.rand.randf() * (@teleportBoundary.x2 - @teleportBoundary.x) + @teleportBoundary.x
    y = @world.rand.randf() * (@teleportBoundary.y2 - @teleportBoundary.y) + @teleportBoundary.y
    @teleportXY x, y

  teleportXY: (x, y, z) ->
    @setTargetXY x, y, (z ? @pos.z), 'teleportXY'
    @setTeleport()

  teleport: (pos) ->
    @setTargetPos pos, 'teleport'
    @setTeleport()
    
  setTeleport: ->
    if @acts
      @setAction "teleport"
      if @targetPos and @distance(@targetPos) < 1 then "done" else "teleport"
    else
      @pos = @targetPos
      @targetPos = null
      @hasMoved = true

  update: ->
    if @action is 'teleport' and @targetPos and @act()
      @pos = @targetPos
      @targetPos = null
      @hasMoved = true
      @setAction 'idle'
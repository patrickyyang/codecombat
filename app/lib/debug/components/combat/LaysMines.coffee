Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class LaysMines extends Component
  @className: 'LaysMines'

  attach: (thang) ->
    layMineAction = name: 'lay-mine', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions layMineAction

  layMine: (targetPos) ->
    if targetPos and not (targetPos.x? and targetPos.y?)
      throw new ArgumentError "#{@id} needs an {x, y} position at which to lay a mine.", "layMine", "targetPos", "object", targetPos
    @setTargetPos targetPos ? Vector.add(@pos, new Vector(@mineLayingRange, 0).rotate(@rotation)), 'layMine'
    if @actions.move and @distance(@targetPos) > @mineLayingRange
      @setAction 'move'
    else
      @setAction 'lay-mine'

  update: ->
    if @action is 'lay-mine' and not @targetPos
      return @setAction 'idle'
    return unless @action is 'lay-mine' and @distance(@targetPos) < @mineLayingRange and @act()
    unless @mineSpriteName
      mineThang = @world.getThangByID @mineThangID
      unless mineThang
        console.log @id, "LaysMines problem: couldn't find mine to lay for ID", @mineThangID
        return
      @mineSpriteName = mineThang.spriteName
      @mineComponents = _.cloneDeep mineThang.components
    return unless @mineSpriteName
    mine = @spawn @mineSpriteName, @mineComponents
    mine.pos = @targetPos
    mine.addTrackedProperties ['pos', 'Vector']
    mine.keepTrackedProperty 'pos'
    @setTargetPos null
    mine.setExists true
    @hidden = false
    @alpha = 1

Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class Carryable extends Component
  @className: 'Carryable'
  isCarryable: true

  attach: (thang) ->
    super thang
    unless thang.move
      thang.addTrackedProperties ['pos', 'Vector']
      thang.keepTrackedProperty 'pos'

  update: ->
    if @parent?
      @pos.x = @parent.pos.x
      @pos.y = @parent.pos.y
      @pos.z = @anchorDepth + @parent.pos.z - @parent.depth / 2
      @velocity?.z = 0

  setParent: (parent) ->
    @parent = parent
    

  removeParent: ->
    @parent = null

  onCollect: (collector) ->
    return false unless @autoCarry
    return false if @parent
    return false unless collector.doPickUpItem
    return true unless collector.canPickUpItem @
    collector.setTarget @
    collector.doPickUpItem()
    true

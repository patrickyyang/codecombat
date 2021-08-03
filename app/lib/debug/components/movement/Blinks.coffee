Component = require 'lib/world/component'

Vector = require 'lib/world/vector'
{ArgumentError} = require 'lib/world/errors'

module.exports = class Blinks extends Component
  @className: 'Blinks'
  @hasBlinked = false
  
  constructor: (config) ->
    super config
    @portalThangType = (@requiredThangTypes ? [])[0]
    
  attach: (thang) ->
    blinkAction = name: 'blink', cooldown: @cooldown, specificCooldown: @specificCooldown, blinkRange: @blinkRange
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.requiredThangTypes = (thang.requiredThangTypes ? []).concat(@requiredThangTypes ? [])
    thang.componentsForThangType @portalThangType if @portalThangType  # Make sure the Components are saved to the world's classMap.
    delete @requiredThangTypes
    thang.addActions blinkAction

  blink: (pos) ->
    unless pos?
      throw new ArgumentError "You need to blink towards a position!"
    if (pos.isVector) or (_.isPlainObject(pos) and (pos.x? and pos.y?))
      @setTargetPos pos
    else
      throw new ArgumentError "Target an {x: number, y: number} position.", "blink", "pos", "object", pos
    if @requireLineOfSight and not @isPathClear(@pos, pos, null, true)
      @sayWithoutBlocking? "I can't get there."
      return
    @setAction 'blink'
    @block()
  
  configurePortal: ->
    if @portalThangType
      @portalComponents = _.cloneDeep @componentsForThangType @portalThangType
      @portalSpriteName = _.find(@world.thangTypes, original: @portalThangType)?.name ? @portalComponents

  
  performBlink: () ->
    blinkVector = Vector.subtract(@getTargetPos(), @pos).limit(@blinkRange)
    if @turnToDirection
      @rotation = blinkVector.heading()
      @keepTrackedProperty("rotation")
      @hasRotated = true
    newPos = @pos.copy().add(blinkVector)
    #@sayWithoutBlocking? "Blink!"
    @configurePortal() unless @portalComponents
    if @portalComponents
      #console.log("READY", @portalSpriteName)
      portalFrom = @spawn @portalSpriteName, @portalComponents
      portalFrom.pos = @pos.copy()
      portalFrom.addTrackedProperties ['pos', 'Vector']
      portalFrom.keepTrackedProperty 'pos'
      portalTo = @spawn @portalSpriteName, @portalComponents
      portalTo.pos = newPos.copy()
      portalTo.addTrackedProperties ['pos', 'Vector']
      portalTo.keepTrackedProperty 'pos'
    @pos = newPos
    @keepTrackedProperty("pos")
    @setAction 'idle'
    @hasMoved = true

  update: ->
    return unless @action is 'blink' and @act()
    @unblock()
    @performBlink()



    

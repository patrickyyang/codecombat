Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

VALID_PLAYERS = ['goliath']
VALID_RECRUITS = ['griffin', 'tiger', 'wolf']

module.exports = class PongArenaAPI extends Component
  @className: 'PongArenaAPI'

  # chooseAction: ->

  constructor: (config) ->
    super config
    
  attach: (thang) ->
    super thang
    thang.teammates = []
    thang.addTrackedProperties ['teammates', 'array']

  initialize: ->
    @direction = if @team is "humans" then 1 else -1
    @lastHit = 0
    @hitCooldown = 1

  findNearestBall: ->  
    @world.getThangByID "ball"
    
  update: ->
    return unless @proxyHero
    @proxyHero.pos = @pos.copy()
    for prop in @trackedPropertiesKeys
      @proxyHero[prop] = if @[prop]?.copy then @[prop].copy() else @[prop]
    # @proxyHero.hasMoved = true
    # TODO: put all components on the primary hero thang, and then add checks for playAs type to enable/disable
    console.log "POS", @pos, @proxyHero.pos unless _.isEqual(@pos, @proxyHero.pos)
    
  playAs: (type) ->
    if @playingAs
      throw new Error "You can only use playAs once."
    if @world.frames.length > 1
      throw new Error "Use playAs at the start of your code!"
    unless type in VALID_PLAYERS
      throw new Error "You can playAs: " + VALID_PLAYERS.join(', ')
    @playingAs = type
    @buildXY type, @pos.x, @pos.y
    @proxyHero = @performBuild()
    @proxyHero.cancelCollisions()
    @proxyHero.hidden = true
    @proxyHero.isAttackable = false
    @proxyHero.updateRegistration()
    @proxyHero.keepTrackedProperty 'pos'
    @proxyHero.trackedPropertiesKeys = @trackedPropertiesKeys
    @proxyHero.trackedPropertiesTypes = @trackedPropertiesTypes
    @proxyHero.trackedPropertiesUsed = _.clone @trackedPropertiesUsed
    @trackPropertiesUsed = (false for prop in @trackedPropertiesUsed)
    # Any properties tracked on the hero should be tracked on the proxy instead.
    @keepTrackedProperty = (prop) =>
      propIndex = @proxyHero.trackedPropertiesKeys.indexOf prop
      if propIndex isnt -1
        @proxyHero.trackedPropertiesUsed[propIndex] = true
        # @trackedPropertiesUsed[propIndex] = true
        
    @mass = @proxyHero.mass
    @attackRange = @proxyHero.attackRange
    @isHittable = true



  recruit: (type) ->
    if type not in VALID_RECRUITS
      throw new Error "You can recruit: " + VALID_RECRUITS.join(', ')
    if @teammates.length >= 2
      throw new Error "You can only recruit 2 teammates."
    if type in @teammates
      throw new Error "You can't recruit #{type} twice!"
    @buildXY type, @pos.x + @direction * 2, @pos.y
    thang = @performBuild()
    @teammates.push type
    @keepTrackedProperty 'teammates'
    thang.direction = @direction
    thang.isHittable = true
    thang.moveTo = @moveTo
    thang.moveToXY = @moveToXY
    thang.hit = @hit
    thang.moveToward = @moveToward
    thang.moveTowardPos = @moveTowardPos
    thang.lastHit = 0
    thang.hitCooldown = @hitCooldown
    thang

    
  moveTo: (args...) ->
    if args.length is 2 and _.isNumber(args[0]) and _.isNumber(args[1])
      @moveToXY args[0], args[1]
      return
    if args.length is 1 and _.isObject(args[0]) and _.isNumber(args[0]?.x) and _.isNumber(args[0]?.y)
      @moveToXY args[0].x, args[0].y
      return
    throw new Error "You must moveTo(x,y) or moveTo(pos)."

  moveToXY: (x, y) ->
    # Hack because collision with river isn't working.
    # TODO: figure out river collision and then remove this?
    unless @locomotionType is 'flying'
      crop = if @direction > 0 then Math.min else Math.max
      limit = 40 - (@direction * 2)
      x = crop(x, limit)
    @moveXY(x, y)
    
  moveToward: (args...) ->
    if args.length is 2 and _.isNumber(args[0]) and _.isNumber(args[1])
      @moveTowardPos(new Vector(args[0], args[1]))
      return
    if args.length is 1 and _.isObject(args[0]) and _.isNumber(args[0]?.x) and _.isNumber(args[0]?.y)
      @moveTowardPos args[0]
      return
    throw new Error "You must moveToward(x,y) or moveToward(pos)."

  moveTowardPos: (pos) ->
    moveTo = pos.copy()
    unless @locomotionType is 'flying'
      crop = if @direction > 0 then Math.min else Math.max
      limit = 40 - (@direction * 2)
      moveTo.x = crop(moveTo.x, limit)
    @move(moveTo)
  
  hit: (target, pos) ->
    # console.log "HIT", @id, target.id, @world.age
    unless target?
      throw new ArgumentError "Target is null. Should be the ball or an opponant.", "hit", "target", "object", target
    unless target.pos? and target.isHittable?
      throw new Error "You must target the ball or an opposing player."
    return unless @world.age >= @lastHit
    distance = @distanceTo target
    maxRangeFactor = 2
    maxRange = @attackRange * maxRangeFactor
    if distance > maxRange
      @sayWithoutBlocking? "It's out of range!"
      return
    dir = pos.copy().subtract(target.pos).normalize()
    force = @mass
    modifier = 0
    if distance > @attackRange
      modifier = Math.pow((distance - @attackRange) / @attackRange, 2)
    force = @mass - (@mass * modifier)
    momentum = dir.multiply(force).divide(target.mass || 1)
    target.velocity.add(momentum)
    @lastHit = @world.age + @hitCooldown




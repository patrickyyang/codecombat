Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class GameMechanics extends Component
  @className: 'GameMechanics'

  attach: (thang) ->
    super thang
    # Helper game mechanic for Game Dev newbies. 
    # thang is the mcp
    thang.fn ?= {}
    thang.fn.destroy = @destroyHandler.bind(thang)
    thang.fn.defeat = @defeatHandler.bind(thang)
    thang.fn.destroyOther = @destroyOtherHandler.bind(thang)
    thang.fn.defeatOther = @defeatOtherHandler.bind(thang)
    thang.fn.takeDamage = @takeDamageHandler.bind(thang)
    thang.fn.takeDamageOther = @takeDamageOtherHandler.bind(thang)
    thang.fn.moveUp = @moveDir('up').bind(thang)
    thang.fn.moveDown = @moveDir('down').bind(thang)
    thang.fn.moveLeft = @moveDir('left').bind(thang)
    thang.fn.moveRight = @moveDir('right').bind(thang)
    thang.fn.moveToward = @moveTowardHandler.bind(thang)
    thang.fn.moveTo = @moveToHandler.bind(thang)
    thang.fn.teleportTo = @teleportToHandler.bind(thang)
    thang.fn.addScore = @addScoreHandler.bind(thang)
    thang.fn.jump = @jumpHandler.bind(thang)
    thang.fn.stop = @stopHandler.bind(thang)
    thang.fn.gameOver = @gameOverHandler.bind(thang)
    thang.fn.spawn = @spawnHandler.bind(thang)
  
  getHandlerTargets: (target) ->
    handlerTargets = []
    if typeof(target) is "string"
        handlerTargets = (th for th in @world.thangs when th.exists and th.type is target)
      else
        handlerTargets = [target]
    return handlerTargets
  
  actionHandler: (fnName, target, event, args...) ->
    actionTargets = @getHandlerTargets(target ? event.target)
    for actionTarget in actionTargets when actionTarget
      actionTarget[fnName]?(args...)
  
  destroyHandler: (target) ->
    mcp = @
    (event) ->
      mcp.actionHandler("esper_destroy", target, event)

  defeatHandler: (target) -> 
    mcp = @
    (event) ->
      
      mcp.actionHandler("esper_defeat", target, event)
  
  takeDamageHandler: (damage, target) -> 
    mcp = @
    (event) ->
      mcp.actionHandler("takeDamage", target, event, damage)
  
  destroyOtherHandler: () -> (event) ->
    if event.other
      event.other.esper_destroy?()

  defeatOtherHandler: () -> (event) ->
    if event.other
      event.other.esper_defeat?()
  
  
  takeDamageOtherHandler: (damage, target) -> (event) ->
    if event?.other
      event.other.takeDamage?(damage)
      
  moveDir: (direction) -> (target) ->
    world = @world
    (event) ->
      handlerTarget = target ? event.target
      if typeof(handlerTarget) is "string"
        moveTargets = (th for th in world.thangs when th.exists and th.type is handlerTarget)
      else
        moveTargets = [handlerTarget]
      for moveTarget in moveTargets
        if not moveTarget.maxSpeed?
          moveTarget.esper_maxSpeed = 10
        if moveTarget?.pos?.copy and moveTarget.maxSpeed
          distance = moveTarget.maxSpeed * world.dt
          pos = moveTarget.pos.copy()
          switch direction
            when 'up' then pos.y += distance
            when 'down' then pos.y -= distance
            when 'left' then pos.x -= distance
            when 'right' then pos.x += distance
          moveTarget.move(pos)
  
  # TODO: move methods can generalized
  moveTowardHandler: (handlerTarget, pos) ->
    world = @world
    (event) ->
      handlerTarget ?= event.target
      if typeof(handlerTarget) is "string"
        moveTargets = (th for th in world.thangs when th.exists and th.type is handlerTarget)
      else
        moveTargets = [handlerTarget]
      toPos = pos || event.pos
      for moveTarget in moveTargets
        if not moveTarget.maxSpeed?
          moveTarget.esper_maxSpeed = 10
        moveTarget.move?(toPos)

  moveToHandler: (handlerTarget, pos) ->
    world = @world
    (event) ->
      handlerTarget ?= event.target
      if typeof(handlerTarget) is "string"
        moveTargets = (th for th in world.thangs when th.exists and th.type is handlerTarget)
      else
        moveTargets = [handlerTarget]
      toPos = pos || event.pos
      for moveTarget in moveTargets
        if not moveTarget.maxSpeed?
          moveTarget.esper_maxSpeed = 10
        moveTarget.moveXY?(toPos.x, toPos.y) unless moveTarget.action is 'move'
          
    # event.pos is set on click events
    
    
  
  teleportToHandler: (x, y, target) -> (event) ->
    target ?= event.target
    # event.pos is set on click events
    return unless target and target.pos
    if x? and y? and _.isNumber(x) and _.isNumber(y)
      toPos = new Vector(x, y, target.pos.z)
    else  
      toPos = event.pos
    if toPos and toPos.copy
      target?.pos = toPos.copy?()
  
  addScoreHandler: (score) -> 
    gameReferee = @
    @ui_track?(@, "score")
    (event) ->
      gameReferee.score ?= 0
      gameReferee.score += score
      
  jumpHandler: (force, target) -> 
    mcp = @
    (event) ->
      target ?= event.target
      jumpers = [target]
      world = mcp.world
      return if not world.gameGravity
      if typeof(target) is 'string'
        jumpers = (t for t in world.thangs when t.exists and t.type is target)
      for jumper in jumpers
        continue if jumper.jumped or jumper._jumpVector
        jumper.once 'collide', (event) -> event.target.jumped = false
        gravityDirection = world.gameGravity.copy().normalize()
        jumper._jumpVector = gravityDirection.multiply(-1).multiply(force)
        jumper.jumped = true
      
      
  
  stopHandler: (target) -> (event) ->
    stopTarget = target ? event.target
    stopTarget?.velocity?.limit(0)
    
  gameOverHandler: () -> 
    world = @world
    (event) ->
      world.endWorld(true, 1)
      
  spawnHandler: (type, pos, cost=0) -> 
    mcp = @
    (event) ->
      return if cost and mcp.score < cost
      spawnPos = pos ? event.pos
      return unless spawnPos
      mcp.spawnXY(type, spawnPos.x, spawnPos.y)
      mcp.score -= cost
      
  

Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

keyMap =
  "space": " "

module.exports = class GameInput extends Component
  @className: 'GameInput'
  
  
  onKey: (key, handler) ->
    return unless key?.toLowerCase
    
    @keyEventHandlers ?= {}
    key = key.toLowerCase()
    key = keyMap[key] if keyMap[key]
    @keyEventHandlers[key] ?= []
    @keyEventHandlers[key].push(handler)
    @on("keyheld", @keydownHandler.bind(@))
  
  keydownHandler: (event) ->
    return unless event.keyCode
    keyChar = String.fromCharCode(event.keyCode)?.toLowerCase()
    if @keyEventHandlers?[keyChar]
      for handler in @keyEventHandlers[keyChar]
        @eventQueue.push data: _.clone(event), handler: handler
  
  defaultClickHandler: (event) ->
    #console.log _.keys(event)
    player = event.target
    if event.type is 'click'
      target = event.target.world.getThangByID event.thangID
      if target and target.team isnt player.team and target.health > 0
        player.attack? target
      else
        world = event.target.world
        nearby = (u for u in world.thangs when not u.isPlayer and u.team isnt world.player.team and u.isAttackable and u.health > 0 and u.pos.distanceSquared(event.pos) <= 4)
        if nearby.length > 0
          # console.log "NEAR CLICK ATTACK!!"
          player.attack? nearby[0]
        else
          player.move event.pos

  defaultKeydownHandler: (event) ->
    #console.log "keydown", event.keyCode, event.ctrlKey, event.metaKey, event.shiftKey, event.time
    player = event.target

    if event.keyCode == 32 or event.keyCode == 67
      # 32 = space, 67 = c
      if player.isReady?("cleave")
        player.cleave?()
      else
        player.sayWithoutBlocking "..."

  defaultKeyheldHandler: (event) ->
    player = event.target
    world = player.world
    #console.log "keyheld", event.keyCode, event.ctrlKey, event.metaKey, event.shiftKey, event.time, world.age
    # w = 87 , s= 83, a = 65 , d = 68
    
    player.inputVector ?= new Vector(0, 0)
    speed = player.maxSpeed / 10
    if event.keyCode == 83
      #console.log "s key"
      player.inputVector.add(new Vector(0, -speed))
    else if event.keyCode == 87
      #console.log "w key"
      player.inputVector.add(new Vector(0, speed))
    else if event.keyCode == 65
      #console.log "a key"
      player.inputVector.add(new Vector(-speed, 0))
    else if event.keyCode == 68
      #console.log "d key"
      player.inputVector.add(new Vector(speed, 0))
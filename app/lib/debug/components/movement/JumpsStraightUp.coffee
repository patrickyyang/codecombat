Component = require 'lib/world/component'

module.exports = class JumpsStraightUp extends Component
  @className: "JumpsStraightUp"
  
  attach: (thang) ->
    @_jumpAction = name: 'jump', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions @_jumpAction
    thang.jumpTime = thang.calculateJumpTimeForHeight @jumpHeight
    thang.actions.jump.cooldown ?= thang.jumpTime / 4
    thang.actions.jump.specificCooldown ?= thang.jumpTime

  jump: ->
    @setAction 'jump'
    @block()
    
  calculateJumpTimeForHeight: (jumpHeight) ->
    jumpHeight ?= @jumpHeight
    2 * Math.sqrt(2 * jumpHeight / @world.gravity)
    
  updateJumpTime: ->
    oldJumpTime = @jumpTime
    @jumpTime = @calculateJumpTimeForHeight @jumpHeight
    if @actions.jump.specificCooldown is oldJumpTime
      @actions.jump.specificCooldown = @jumpTime
    if @actions.jump.cooldown is oldJumpTime / 4
      @actions.jump.cooldown = @jumpTime / 4  # Let us do stuff part of the way through the jump
    
  update: ->
    if @action is 'jump' and @isGrounded() and @act()
      @unblock()
      @velocity.z = @world.gravity * @jumpTime / 2
      #console.log @id, 'jumped, setting velocity z to', @velocity.z, 'with jumpTime', @jumpTime

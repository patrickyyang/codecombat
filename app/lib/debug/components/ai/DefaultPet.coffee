Component = require 'lib/world/component'

module.exports = class DefaultPet extends Component
  @className: 'DefaultPet'
  
  attach: (thang) ->
    super thang
    thang.hasBeenCommanded = false
  
  chooseAction: ->
    return if @gameEntity or @isPlayer
    if @commander? and @move?
      if @future
        @hasBeenCommanded = true
      unless @hasBeenCommanded
        dir = @commander.pos.copy().subtract(@pos).normalize().multiply(1)
        @rotation = dir.heading() if @action isnt "attack"
        if @distanceTo?(@commander) > 6
          @move @commander.pos
        else if @distanceTo(@commander) > 3
          @brake?()
        else
          if @isPathClear @pos, {x:@pos.x + dir.y, y:@pos.y - dir.x}
            @move {x:@pos.x + dir.y, y:@pos.y - dir.x}
          else
            if @action isnt "idle"
              @setAction "idle"
              @brake()
  
  assist: () ->
    @hasBeenCommanded = false
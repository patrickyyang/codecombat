Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class Scampers extends Component
  @className: 'Scampers'
  chooseAction: ->
    if @world.age is 0
      @idleUntil = @world.age + @world.rand.randf() * 5
    @stopScampering() if @targetPos and (@velocity.magnitude() < 2 or (@collisionCategory isnt 'none' and @distance(@targetPos) < 2))
    return if @targetPos
    return if @idleUntil and @world.age < @idleUntil
    if @idleUntil
      if @scamper()
        @idleUntil = null
    else
      @stopScampering()
      @idleUntil = @world.age + @world.rand.randf() * 10
  
  scamper: ->
    # Move until we hit an obstacle in a random direction.
    angle = @world.rand.randf() * 2 * Math.PI
    @aiSystem ?= @world.getSystem("AI")
    grid = @aiSystem.getNavGrid()
    distance = 1
    maxDistance = 20 + @world.rand.randf() * 20
    until distance > maxDistance or grid.contents(@pos.x + Math.cos(angle) * distance, @pos.y + Math.sin(angle) * distance).length
      distance += 0.5
    if distance > 1
      @move new Vector(@pos.x + Math.cos(angle) * distance, @pos.y + Math.sin(angle) * distance)
      return true
    false
    
  stopScampering: ->
    @setTargetPos null
    @setAction 'idle'
    @brake?()
    
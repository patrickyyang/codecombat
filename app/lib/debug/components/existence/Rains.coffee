Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class Rains extends Component
  @className: 'Rains'
  
  chooseAction: ->
    @brake = ->  # Don't brake, we need to rain while possibly moving
    @summon @buildTypes[@world.rand.rand @buildTypes.length] if not @rainCount or @rainCount > @built.length

  update: ->
    # Hacks for raining things that don't even moveg
    for rain in @built when rain.exists
      if rain.raining and rain.pos.z > rain.depth / 2
        #rain.velocity.z -= @world.gravity * @world.dt
        if @world.getSystem("Movement").hasGravitationalAnomalies
          rain.velocity.z -= @world.getSystem("Movement").gravityAt(rain.pos) * @world.dt
        else
          rain.velocity.z -= 9.8 * @world.dt  # TODO: the one world where I want to use this, I set the gravity mad high for missile arcs
        rain.pos.add Vector.multiply(rain.velocity, @world.dt)
        rain.pos.z = Math.max 0, rain.depth / 2
        if rain.wasCollectable and rain.pos.z < rain.depth / 2 + 1
          rain.isCollectable = true
          rain.wasCollectable = false
          rain.updateRegistration()
      else
        couldMove = rain.velocity?
        rain.velocity = new Vector(@world.rand.randfRange(0, 5), @world.rand.randfRange(0, 5), @world.rand.randfRange(2, 4))
        unless couldMove
          rain.addTrackedProperties ['pos', 'Vector']
          rain.keepTrackedProperty 'pos'
          rain.raining = true
          if rain.isCollectable
            rain.wasCollectable = true
            rain.isCollectable = false
            rain.updateRegistration()
  
    if @bouncesWhileRaining and (not @rainCount or @built.length < @rainCount)
      # Bounce off upcoming obstacles in four cardinal directions if we're still raining.
      @aiSystem ?= @world.getSystem "AI"
      v = @velocity.copy()
      speed = v.magnitude()
      d = speed * 2 * @world.dt
      forward = new Vector d, 0
      sideways = new Vector 0, d
      forward.multiply -1 if v.x < 0
      sideways.multiply -1 if v.y < 0
      clearForward = @aiSystem.isPathClear @pos, @pos.copy().add(forward), @, true
      clearSideways = @aiSystem.isPathClear @pos, @pos.copy().add(sideways), @, true
      @velocity.x *= -1 if not clearForward
      @velocity.y *= -1 if not clearSideways

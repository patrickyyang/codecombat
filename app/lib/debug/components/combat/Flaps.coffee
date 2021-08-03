Component = require 'lib/world/component'

module.exports = class Flaps extends Component
  @className: 'Flaps'

  attach: (thang) ->
    flapAction = name: 'flap', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions flapAction

  flap: ->
    @setAction 'flap'
    
  update: ->
    if @action is 'flap' and @act()
      @sayWithoutBlocking? '<FLAP>'
      for mover in @world.getSystem('Movement').movers when (d = @distance(mover)) < @flapRadius and mover isnt @
        ratio = 1 - d / @flapRadius
        momentum = mover.pos.copy().subtract(@pos, true).multiply(ratio * @flapWindMass, true)
        mover.velocity.add momentum.divide(mover.mass, true), true
        mover.rotation = (mover.velocity.heading() + Math.PI) % (2 * Math.PI)
      args = [parseFloat(@pos.x.toFixed(2)), parseFloat(@pos.y.toFixed(2)), parseFloat(@flapRadius.toFixed(2)), 'rgba(163, 189, 215, 0.1)']
      @addCurrentEvent? "aoe-#{JSON.stringify(args)}"

Component = require 'lib/world/component'

module.exports = class Aura extends Component
  @className: 'Aura'

  chooseAction: ->
    @drawAura() if @world.frames.length % 2 is 0 and @showAura and @world.rand.randf() < @auraFlicker

  drawAura: ->
    X = parseFloat((@pos.x+@auraOffsetX).toFixed(2))
    Y = parseFloat((@pos.y+@auraOffsetY).toFixed(2))
    aura = [X, Y, @auraRadius, @auraColor, 0, 0, 'floating']
    @addCurrentEvent "aoe-#{JSON.stringify(aura)}"
    
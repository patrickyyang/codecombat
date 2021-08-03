Component = require 'lib/world/component'

module.exports = class JumpsTooMuch extends Component
  @className: "JumpsTooMuch"
  chooseAction: ->
    if @canAct('jump') and @world.rand.randf() < 0.05
      @setAction 'jump'
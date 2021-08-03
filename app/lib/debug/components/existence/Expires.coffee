Component = require 'lib/world/component'

module.exports = class Expires extends Component
  @className: "Expires"
  update: ->
    @lifespan -= @world.dt
    if @lifespan <= 0
      @setExists false



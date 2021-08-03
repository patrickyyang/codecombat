Component = require 'lib/world/component'

module.exports = class TracksTime extends Component
  @className: 'TracksTime'
  now: -> @world.age
  
  attach: (thang) ->
    super thang
    Object.defineProperty(thang, 'time', {
      get: () -> @world.age,
      set: (x) -> throw new Error("You can't set hero.time")
    })
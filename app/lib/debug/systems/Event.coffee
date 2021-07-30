System = require 'lib/world/system'

module.exports = class Event extends System
  constructor: (world, config) ->
    super world, config
    @eventfulThangs = @addRegistry (thang) -> thang.currentEvents  # even ones that don't exist, since we might need to clear out events on just stopped existing

  update: ->
    # Happens before other Systems, so we can clear out the last currentEvents and get ready for the next
    hash = 0
    for thang in @eventfulThangs
      hash += @hashString(thang.id) * thang.currentEvents.length * @world.age
      thang.currentEvents = []
    hash

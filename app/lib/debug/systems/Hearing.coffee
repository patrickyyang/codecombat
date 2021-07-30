System = require 'lib/world/system'

# TODO: figure out whether range should be done in terms of voiceRange or hearingRange or both
# Idea: create some sort of Range System or Component or something to keep track of various ranges, testing whether things are or aren't in them, handling interactions between to- and from- ranges, displaying range radius circles, whether ranges are hard or soft, etc.

module.exports = class Hearing extends System
  constructor: (world, config) ->
    super world, config
    @speakers = @addRegistry (thang) -> thang.say and thang.exists
    @hearers = @addRegistry (thang) -> thang.hear and thang.exists and not thang.dead

  update: ->
    hash = 0
    for speaker in @speakers
      continue unless speaker.sayMessage and speaker.sayStartPos
      if speaker.sayRemainingAge <= 0
        speaker.clearSpeech()
        continue
      speaker.sayRemainingAge -= @world.dt
      hash += @hashString(speaker.id + speaker.sayMessage) * speaker.sayRemainingAge
      for hearer in @hearers
        continue if hearer is speaker or speaker.sayHeardBy?[hearer.id]
        speechAge = @world.age - speaker.sayStartTime
        continue if speechAge <= Math.min speaker.sayDuration - 3 * @world.dt, hearer.hearingDelay
        speechDistanceSquared = Math.min speaker.sayStartPos.distanceSquared(hearer.pos), speaker.pos.distanceSquared(hearer.pos)
        continue if speechDistanceSquared > speaker.voiceRangeSquared  # TODO: integrate hearing range somehow?
        hearer.hear speaker, speaker.sayMessage, speaker.sayData
        hearer.trigger? "hear", speaker: speaker, message: speaker.sayMessage, sayData: speaker.sayData
        speaker.sayHeardBy?[hearer.id] = true
        #console.log hearer.id, "heard", speaker.id, "say", speaker.sayMessage, "with data", speaker.sayData, "at time", @world.age
        hash += @hashString(hearer.id + speaker.sayMessage) * speaker.sayRemainingAge
    hash
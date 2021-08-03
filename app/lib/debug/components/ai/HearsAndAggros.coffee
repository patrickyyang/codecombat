Component = require 'lib/world/component'

module.exports = class HearsAndAggros extends Component
  @className: "HearsAndAggros"
  hear: (speaker, message) ->
    #console.log @id, "hearing", speaker.id, "say", message, "with target", speaker.target?.id
    if speaker.team isnt @team
      target = speaker
    else if speaker.target and speaker.target.isAttackable and speaker.target.team isnt @team
      target = speaker.target
    if target
      if (@heardAggroMessages ?= {})[message] and @aggroResponses.length
        @say "Heard that one before."
        return
      @heardAggroMessages[message] = true
      unless @aggroResponses.length > 1
        @attack target
      if @aggroResponses.length
        @say @aggroResponses.shift()
        # Kind of a hack: since chooseAction won't necessarily trigger, we apply the cooldown here
        if @actions.say
          @heat = Math.max @heat, @actions.say.cooldown

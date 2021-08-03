Component = require 'lib/world/component'

# To use this, set @dialogues to be an array of phrases in the Referee.
# An action is an array:
# [time, name, phrase]

module.exports = class DialoguesReferee extends Component
  @className: 'DialoguesReferee'
  chooseAction: ->
    return if not @dialogues or not @dialogues.length
    for d in @dialogues when d.length and d.length >= 3
      if Math.abs(@world.age - d[0]) < @world.dt
        actor = @world.getThangByID(d[1])
        if actor and ((actor.health? and actor.health > 0) or not actor.health?)
          actor.say?(d[2])
      
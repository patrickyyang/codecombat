Component = require 'lib/world/component'

module.exports = class SarvenShepherdReferee extends Component
  @className: 'SarvenShepherdReferee'

  controlNeutral: (yaks) ->
    for yak in yaks when yak.exists
      if yak.waypoints?.length is 0
        yak.exists = false
      else if yak.currentSpeedRatio > .15
        yak.currentSpeedRatio = .15

  checkVictory: ->
    return if @victoryOgres
    return unless @world.age > 31
    livingOgres = (t for t in @world.thangs when t.team is 'ogres' and t.health > 0)
    if livingOgres.length == 0
      @victoryOgres = true
      @setGoalState 'ogres-die', 'success'
      @world.endWorld true, 1

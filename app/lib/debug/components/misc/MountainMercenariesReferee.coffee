Component = require 'lib/world/component'

module.exports = class MountainMercenariesReferee extends Component
  @className: 'MountainMercenariesReferee'

  setUpLevel: ->
    @victoryTime = 60
    @victoryOgres = false
  
  checkVictory: ->
    return if @victoryOgres
    return unless @world.age > @victoryTime
    livingOgres = (t for t in @world.thangs when t.team is 'ogres' and t.health > 0)
    if livingOgres.length == 0
      @victoryOgres = true
      @setGoalState 'ogres-die', 'success'
      @world.endWorld true, 3

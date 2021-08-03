Component = require 'lib/world/component'

module.exports = class YakstractionReferee extends Component
  @className: 'YakstractionReferee'

  controlNeutral: (thangs) ->
    if @surviving.humans.length
      for yak in thangs when yak.exists
        yak.maxSpeed = 5
        yak.currentSpeedRatio = 1
        if yak.target?.type is 'decoy'
          yak.decoyTarget = yak.target
          yak.waypoints = null
          console.log @world.age, 'no more waypoints for', yak.id
        human = yak.findNearest @surviving.humans
        if yak.distance(human) < 5
          console.log @world.age, 'telling yak to attack', human.id, 'at d', yak.distance(human)
          yak.waypoints = null
          yak.attack human
        else if yak.decoyTarget?.health > 0
          yak.attack yak.decoyTarget
        unless @rectangles.yakExistenceArea.containsPoint yak.pos
          yak.setExists false

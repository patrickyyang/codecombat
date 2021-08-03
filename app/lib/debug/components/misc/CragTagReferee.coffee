Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class CragTagReferee extends Component
  @className: 'CragTagReferee'
  chooseAction: ->
    @postSetUp() if not @didPostSetUp
    @controlPender() if @pender

  setUpLevel: ->
    @pender = @world.getThangByID('Pender Spellbane')
    @pender.waypoint = 0
    @pender.taunt = 0
    @pender.caught = false
    @victoryChecked = false
    @setUpPenderPoints()
    @pender.pos = @penderPoints[0]
    @setUpTaunts()

  setUpPenderPoints: ->
    @penderPoints = []
    r = 24
    # Plot out a loop
    for i in [0...12]
      a = (2.0 * Math.PI / 12.0) * i
      px = 40 + r * Math.cos(a)
      py = 32 + r * Math.sin(a)
      @penderPoints.push(new Vector(px, py))

    # Rotate the list so that it starts in a different spot
    n = @world.rand.rand(@penderPoints.length)
    @penderPoints = @penderPoints.slice(n, @penderPoints.length).concat(@penderPoints.slice(0, n))

    # Reverse the loop maybe?
    if @world.rand.randf() < 0.5
      @penderPoints.reverse()

  setUpTaunts: ->
    @tauntDelay = 7
    @tauntTime = @world.age
    @taunts = [
      "Catch me if you can!"
      "Pick up the pace!"
      "Where are you even going?"
      "Get the lead out!"
      "You'll never catch me!"
      "C'mon, try to keep up!"
      "Are you out of breath yet?"
    ]
    # Shuffle all except the first taunt.
    for i in [@taunts.length-1..2]
      j = 1 + Math.floor @world.rand.randf() * (i - 2)
      t = @taunts[j]
      @taunts[j] = @taunts[i]
      @taunts[i] = t

    @caughtTaunt = "You got me! Good... but the real test is yet to come."
    @campTaunt = "That's not fair! You have to chase me."

  postSetUp: ->
    @didPostSetUp = true
    # Adjust Pender's speed to match the player's.
    f = @hero.maxSpeed / @pender.maxSpeed
    @pender.maxSpeed *= f * 1.01

  controlPender: ->
    return if @pender.caught
    @pender.move(@penderPoints[@pender.waypoint])
    if @pender.distanceTo(@penderPoints[@pender.waypoint]) < 5
      @pender.waypoint = if @pender.waypoint < @penderPoints.length-1 then @pender.waypoint+1 else 0

    if @pender.distanceTo(@hero) < 4
      if @hero.action is 'idle'
        @pender.say(@campTaunt)
      else
        @pender.caught = true
        @pender.say(@caughtTaunt)

    if not @pender.caught and @world.age > @tauntTime
      @tauntTime = @world.age + @tauntDelay
      @pender.say(@taunts[@pender.taunt])
      @pender.taunt = if @pender.taunt < @taunts.length-1 then @pender.taunt+1 else 1


  checkVictory: ->
    return if @victoryChecked
    if @world.age < 30 and @pender.caught
      @victoryChecked = true
      @pender.caught = true
      @setGoalState 'catch-pender', 'success'
      @world.endWorld true, 1
    if @world.age > 30 and not @pender.caught
      @victoryChecked = true
      @setGoalState 'catch-pender', 'failure'
      @world.endWorld true, 1

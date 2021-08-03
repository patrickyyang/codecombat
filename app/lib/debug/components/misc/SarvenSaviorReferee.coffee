Component = require 'lib/world/component'

module.exports = class SarvenSaviorReferee extends Component
  @className: 'SarvenSaviorReferee'
  chooseAction: ->
    for fn in @friends
      @controlFriend(@world.getThangByID fn)
    @checkVictory()

  setUpLevel: ->
    @didSpawn = false
    @victoryFriends = false
    @victoryFence = false
    @friendHomeDistance = 5
    @ogreXFudge = 5
    @friends = [ 'Joan', 'Ronan', 'Nikita', 'Augustus' ]
    # hollaback flags are set when a character hears its name.
    @hollaback = {}
    for f in @friends
      @world.getThangByID(f).hollaback = @hollaback
      @hollaback[f] = false

  controlFriend: (friend) ->
    if @hollaback[friend.id]
      if not friend.homePoint
        a = @world.rand.randf() * 2 * Math.PI
        d = @friendHomeDistance
        hpx = @points.friendHome.x + d * Math.cos(a)
        hpy = @points.friendHome.y + d * Math.sin(a)
        friend.homePoint = { x:hpx, y:hpy }
      friend.moveXY(friend.homePoint.x, friend.homePoint.y)

  checkVictory: ->
    return if @victoryFriends and @victoryFence

    return unless @world.age > 5
    if not @victoryFriends
      friends = (@world.getThangByID f for f in @friends)
      friendsAtHome = (f for f in friends when f.pos.x < @points.fenceSpot.x)
      if friendsAtHome.length >= 4
        @victoryFriends = true
        @setGoalState 'friends-home', 'success'

    return unless @world.age > 12
    if not @victoryFence
      strayOgres = (o for o in @world.thangs when o.team=='ogres' and o.pos.x < @points.fenceSpot.x-@ogreXFudge)
      if strayOgres.length == 0 and @hero.pos.x < @points.fenceSpot.x + @ogreXFudge and @world.getThangByID('Fence Wall')
        @victoryFence = true
        @setGoalState 'ogres-fenced', 'success'

    if @victoryFriends and @victoryFence
      @world.endWorld true, 1

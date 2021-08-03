Component = require 'lib/world/component'

module.exports = class OddSandstormReferee extends Component
  @className: 'OddSandstormReferee'

  chooseAction: ->
    for fn in @oddSandstormFriends
      @controlFriend(fn)

  setUpLevel: ->
    @oddSandstormFriends = [ 'Tabitha', 'Max', 'Todd' ]
    @victoryOasis = false
    @yakRegions =
      'Arngotho': @rectangles.yakNW
      'Randall': @rectangles.yakNE
      'Falthror': @rectangles.yakSW
      'Langthok': @rectangles.yakSE

  controlFriend: (fn) ->
    return unless @deadOgres() >= 3
    return if @hero.health <= 0
    friend = @world.getThangByID(fn)
    return if friend.health <= 0
    if friend.distanceTo(@hero.pos) > 3
      friend.move x: @hero.pos.x, y: @hero.pos.y - 2

  deadOgres: ->
    dogres = (o for o in @world.thangs when o.team=='ogres' and o.health <= 0)
    return dogres.length

  controlNeutral: (yaks) ->
    return if not @yakRegions
    for y in yaks
      if y.action is 'attack' or y.enraged
        y.enraged = true
        continue
      if not y.movePoint
        region = @yakRegions[y.id] ? @rectangles.yakCenter
        y.movePoint = @pickPointFromRegions([region])
      y.move(y.movePoint)
      if y.distanceTo(y.movePoint) < 4
        y.movePoint = null

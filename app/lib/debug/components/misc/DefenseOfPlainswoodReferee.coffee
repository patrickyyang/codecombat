Component = require 'lib/world/component'

module.exports = class DefenseOfPlainswoodReferee extends Component
  @className: 'DefenseOfPlainswoodReferee'
  chooseAction: ->
    return if @world.age < 10
    return if @victoryChecked
    o1 = @world.getThangByID 'Grumus'
    o2 = @world.getThangByID 'Dronck'
    o1Stopped = o1.dead or o1.pos.y > 50
    o2Stopped = o2.dead or o2.pos.y < 24
    f1 = @world.getThangByID 'Fence Wall'
    f2 = @world.getThangByID 'Fence Wall 1'
    won = o1.dead and o2.dead                      # killed both
    won ||= o1Stopped and o2Stopped and f1 and f2  # fenced both
    won ||= o1.dead and o2Stopped and f1           # killed top, fenced bot
    won ||= o2.dead and o1Stopped and f1           # fenced top, killed bot
    won ||= @world.age > 15 and o1Stopped and o2Stopped  # stopped them some other way
    if won
      @world.endWorld true, 1
      @victoryChecked = true

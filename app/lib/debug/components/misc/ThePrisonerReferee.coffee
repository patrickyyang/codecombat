Component = require 'lib/world/component'

module.exports = class ThePrisonerReferee extends Component
  @className: 'ThePrisonerReferee'

  chooseAction: ->
    @setUp() unless @didSetUp
    @controlArcher()

  setUp: ->
    @didSetUp = true
    @door = @world.getThangByID 'Weak Door'
    
    # Trying to get the barrel to be open. Not working yet.
    #@barrel = @world.getThangByID 'Chamber Pot'
    #@barrel.addActions name: 'open_empty', cooldown: 0
    #@barrel.setAction 'open_empty'   
    #@barrel.act()

  controlArcher: ->
    return unless @door.dead
    archer = @world.getThangByID 'Patrick'
    enemy = archer.getNearestEnemy()
    if enemy
      archer.setTarget enemy
      archer.setAction 'attack'
    else
      archer.setTarget archer.getNearestFriend()
      archer.setAction 'move'

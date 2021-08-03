Component = require 'lib/world/component'

module.exports = class RangeFinderReferee extends Component
  @className: 'RangeFinderReferee'
  chooseAction: ->
    @setUp() unless @didSetUp
    t.blastRadius = 10 for t in @world.thangs when t.spriteName is 'Shell'
    @fireWhenReady()
    #@hero.dSay = @hero.say;
    #@hero.say = (msg, data, _excess) ->
      #if typeof msg is "Number"
      #  msg = "PANIC"
      #@dSay msg, data, _excess
      
  setUpLevel: ->
    @hero.dSay = @hero.say
    @hero.say = (msg, data, _excess) ->
      if typeof msg is 'number'
        msg = msg.toFixed(2)
      @dSay msg, data, _excess
      
  setUp: ->
    @didSetUp = true
    @targets = ['Gort', 'Smasher', 'Charles', 'Gorgnub']
    artillery = @world.getThangByID 'Artillery'
    artillery.fireAtDistance = []

  fireWhenReady: ->
    artillery = @world.getThangByID 'Artillery'
    hero = @world.getThangByID 'Hero Placeholder'
    if artillery.fireAtDistance.length > 0
      console.log('length',artillery.fireAtDistance.length, ' next', artillery.fireAtDistance[0])

      if !artillery.canAct 'attack'
        artillery.say 'Reloading...'
        return
        
      # The distance the player called out
      distance = parseInt artillery.fireAtDistance[0]

      fired = false
      for enemyId in @targets
        enemy = @world.getThangByID enemyId
        continue if enemy.health < 0 || enemy.dead
        d = Math.floor(hero.distanceTo(enemy))
        if d == distance
          console.log('CATSYNC: firing at distance ', d, ' target ', enemy.name)
          artillery.attackXY enemy.pos.x, enemy.pos.y
          artillery.fireAtDistance.shift()
          fired = true
          
      # If there was no valid target at that distance, just fire anyway :)
      if !fired
        artillery.attackXY artillery.pos.x+distance, artillery.pos.y
        artillery.fireAtDistance.shift()
        
    else
      artillery.setAction 'idle'
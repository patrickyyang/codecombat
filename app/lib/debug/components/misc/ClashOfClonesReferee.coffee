Component = require 'lib/world/component'

module.exports = class ClashOfClonesReferee extends Component
  @className: 'ClashOfClonesReferee'

  checkVictoryAfter = 30
  
  chooseAction: ->
    @setUp() unless @didSetUp
    @checkVictory()

  setUp: ->
    @didSetUp = true
    
    @clone = @world.getThangByID 'Hero Placeholder 1'
    @thoktar = @world.getThangByID 'Thoktar'
    
    #yak.isAttackable = false for yak in @world.thangs when yak.type is 'sand-yak'
    yak.startsPeaceful = true for yak in @world.thangs when yak.type is 'sand-yak'
    @thoktar.isAttackable = false
    
    
  checkVictory: ->
    return unless @world.age > checkVictoryAfter
    if @checkedVictoryAt
      if @world.age > @checkedVictoryAt + 2.5
        @thoktar.move {x: @thoktar.pos.x + 50, y: @thoktar.pos.y}
      return
    return if @checkedVictory
    ogresSurviving = (t for t in @world.thangs when t.team is 'ogres' and t.id isnt 'Thoktar' and t.health > 0).length
    if not ogresSurviving
      @setGoalState 'ogres-die', 'success'
      @world.endWorld true, 4
      @checkedVictoryAt = @world.age
      @thoktar.say "I'll be back!"

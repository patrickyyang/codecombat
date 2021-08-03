Component = require 'lib/world/component'

module.exports = class BoulderWoodsReferee extends Component
  @className: 'BoulderWoodsReferee'
  chooseAction: ->
    @configure()
    
  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    
    @boulderSets = [[
      {x: 30.5, y: 45}
      {x: 29, y: 36}
    ], [
      {x: 54, y: 48}
      {x: 50, y: 36}
    ], [
      {x: 13, y: 32}
      {x: 14, y: 39}
    ], [
      {x: 44, y: 55}
      {x: 41, y: 37}
    ], [
      {x: 68, y: 47}
      {x: 69, y: 39}
    ]]
    
  configure: ->
    return unless not @configured
    @hero.findsPaths = false
    @configureBoulders()
    @world.getSystem("AI").onObstaclesChanged()
    @configured = true
  
  configureBoulders: ->
    for set in @boulderSets
      r = Math.round(@world.rand.randf2(0, set.length - 1))
      @instabuild("rock-obstacle", set[r].x, set[r].y)

  checkVictory: ->
    if @rectangles['goal'].containsPoint(@hero.pos)
        @setGoalState 'end-marker', 'success'
    
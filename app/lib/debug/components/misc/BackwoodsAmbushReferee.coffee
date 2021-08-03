Component = require 'lib/world/component'

module.exports = class BackwoodsAmbushReferee extends Component
  @className: 'BackwoodsAmbushReferee'

  setUpLevel: ->
    # Don't randomize ogre1 and ogre2 since they're tied to the sample code.
    spawned3 = @backwoodsAmbushMaybeSpawn('ogre3', .667)
    spawned4 = @backwoodsAmbushMaybeSpawn('ogre4', if spawned3 then .333 else 0.667)
    @backwoodsAmbushMaybeSpawn('ogre5', if spawned4 then 0 else 1)

  backwoodsAmbushMaybeSpawn: (name, chance) ->
    if @world.rand.randf() < chance
      bt = ['ogre-munchkin-f', 'ogre-munchkin-m'][@world.rand.rand 2]
      p = @points[name]
      @instabuild(bt, p.x, p.y)
      return true
    false

  checkVictory: ->
    return if @world.age < 1
    ogresSurviving = (t for t in @world.thangs when t.team is 'ogres' and t.exists and t.health > 0).length
    if not ogresSurviving
      @setGoalState 'ogres-die', 'success'
      @world.endWorld true, 3

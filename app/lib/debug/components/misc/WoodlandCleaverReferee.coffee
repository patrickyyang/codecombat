Component = require 'lib/world/component'

module.exports = class WoodlandCleaverReferee extends Component
  @className: 'WoodlandCleaverReferee'
  chooseAction: ->
    shouldHaveSpawned = @world.age * 0.85
    wave = Math.floor(@world.age / 9.9)
    shouldHaveSpawned += 5.1 * wave
    if shouldHaveSpawned > @built.length and @world.age < 21
      buildType = if @world.rand.randf() < 0.5 then 'ogre-munchkin-m' else 'ogre-munchkin-f'
      @build buildType
      built = @performBuild()
      built.pos.x = 8 + @world.rand.randf() * 36
      built.pos.y = 8 + @world.rand.randf() * 30
      while built.distance(@world.getThangByID('Hero Placeholder')) < 5
        built.pos.x = 8 + @world.rand.randf() * 36
        built.pos.y = 8 + @world.rand.randf() * 30
      built.hasMoved = true

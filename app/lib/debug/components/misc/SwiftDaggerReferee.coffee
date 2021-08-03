Component = require 'lib/world/component'

module.exports = class SwiftDaggerReferee extends Component
  @className: 'SwiftDaggerReferee'
  chooseAction: ->
    shouldHaveSpawned = (@world.age - 1.4) / 1.8
    #wave = Math.floor((@world.age + 0.25) / 10.5)
    #shouldHaveSpawned += 7 * wave
    hero = @world.getThangByID 'Hero Placeholder'
    if shouldHaveSpawned > @built.length and @world.age < 30
      buildType = if @world.rand.randf() < 0.5 then 'ogre-munchkin-m' else 'ogre-munchkin-f'
      @build buildType
      built = @performBuild()
      # Always spawn at attack range
      angle = @world.rand.randf() * Math.PI * 2
      built.pos.x = Math.max(8, Math.min(72, hero.pos.x + 30 * Math.cos angle))
      built.pos.y = Math.max(7, Math.min(68, hero.pos.y + 30 * Math.sin angle))
      built.hasMoved = true

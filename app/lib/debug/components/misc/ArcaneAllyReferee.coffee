Component = require 'lib/world/component'

module.exports = class ArcaneAllyReferee extends Component
  @className: 'ArcaneAllyReferee'
  chooseAction: ->
    shouldHaveSpawned = (@world.age - 6) / 6
    if @world.age > 12
      shouldHaveSpawned += (@world.age - 12) / 12  # Increase spawn rate after Hushbaum drops in
    #wave = Math.floor((@world.age + 0.25) / 10.5)
    #shouldHaveSpawned += 7 * wave
    hero = @world.getThangByID 'Hero Placeholder'
    if shouldHaveSpawned > @built.length and @world.age < 30
      #buildType = if @world.rand.randf() < 0.5 then 'ogre-munchkin-m' else 'ogre-munchkin-f'
      buildType = 'ogre-m'
      @build buildType
      built = @performBuild()
      # Always spawn 10m away from hero
      angle = @world.rand.randf() * Math.PI * 2
      built.pos.x = Math.max(8, Math.min(47, hero.pos.x + 10 * Math.cos angle))
      built.pos.y = Math.max(7, Math.min(39, hero.pos.y + 10 * Math.sin angle))
      built.hasMoved = true

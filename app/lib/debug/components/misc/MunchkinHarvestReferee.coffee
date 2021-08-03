Component = require 'lib/world/component'

module.exports = class MunchkinHarvestReferee extends Component
  @className: 'MunchkinHarvestReferee'
  chooseAction: ->
    shouldHaveSpawned = @world.age * 1.05
    if @world.age > 30
      shouldHaveSpawned += (@world.age - 30) * 0.5  # Increase spawn rate after Amara drops in
    wave = Math.floor((@world.age + 0.25) / 10.1)
    shouldHaveSpawned += 6 * wave
    hero = @world.getThangByID 'Hero Placeholder'
    if shouldHaveSpawned > @built.length and @world.age < 60
      buildType = if @world.rand.randf() < 0.5 then 'ogre-munchkin-m' else 'ogre-munchkin-f'
      @build buildType
      built = @performBuild()
      inWave = hero.findEnemies().length > 3
      if inWave
        # Always spawn within cleave range
        angle = @world.rand.randf() * Math.PI * 2
        built.pos.x = Math.max(8, Math.min(47, hero.pos.x + 10 * Math.cos angle))
        built.pos.y = Math.max(7, Math.min(39, hero.pos.y + 10 * Math.sin angle))
      else
        built.pos.x = 8 + @world.rand.randf() * 39
        built.pos.y = 7 + @world.rand.randf() * 32
        
      built.hasMoved = true

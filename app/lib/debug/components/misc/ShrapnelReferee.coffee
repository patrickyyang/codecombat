Component = require 'lib/world/component'

module.exports = class ShrapnelReferee extends Component
  @className: 'ShrapnelReferee'
  chooseAction: ->
    @initLevel() unless @levelInit
    @wave = Math.floor(@world.age / @waveDelay)
    if @wave != @oldWave
      @offset = 0
      # Change the spawn point whenever the wave ticks over.
      @waveAngle = @world.rand.randf()
      @bodyCount += 2
      if @world.age > 10
        @bodyCount++
    @oldWave = @wave
    if @bodyCount > @built.length and @world.age < 30
      @spawnWave()
      @offset++
      if @offset > 1 # Spawns second munchkin to right and third to left of first
        @offset = -1

  initLevel: ->
    @levelInit = true
    @spawnRange = 30 # Spawn at the edge of attack range
    @waveSpread = .015 # Keep packs tight enough that they all get hit by the charge blast.
    @waveDelay = 5.2 # Last wave should die off right at 29-ish seconds.
    @waveAngle = @world.rand.randf()
    @wave = 0
    @oldWave = 0
    @bodyCount = 0

  spawnWave: ->
    hero = @world.getThangByID 'Hero Placeholder'
    buildType = if @world.rand.randf() < 0.5 then 'ogre-munchkin-m' else 'ogre-munchkin-f'
    @build buildType
    built = @performBuild()

    # Spawn in clumps around the specified angle
    angle = (@waveAngle + @offset * @waveSpread) * Math.PI * 2
    built.pos.x = Math.max(9, Math.min(72, hero.pos.x + @spawnRange * Math.cos angle))
    built.pos.y = Math.max(8, Math.min(68, hero.pos.y + @spawnRange * Math.sin angle))
    built.hasMoved = true
    built.attack hero

Component = require 'lib/world/component'

module.exports = class TouchOfDeathReferee extends Component
  @className: 'TouchOfDeathReferee'
  chooseAction: ->
    @setup() unless @didSetup
    shouldHaveSpawned = Math.floor @world.age / 8
    shouldHaveSpawned *= 3
    hero = @world.getThangByID 'Hero Placeholder'
    livingOgre = hero.getEnemies()[0]
    if shouldHaveSpawned > @built.length and @world.age < 30
      buildType = if @world.rand.randf() < 0.5 then 'ogre-munchkin-m' else 'ogre-munchkin-f'
      @build buildType
      built = @performBuild()
      # Always spawn at attack range
      angle = @world.rand.randf() * Math.PI * 2
      if livingOgre
        built.pos.x = livingOgre.pos.x + (-0.5 + @world.rand.randf()) * 2
        built.pos.y = livingOgre.pos.y + (-0.5 + @world.rand.randf()) * 2
      else
        built.pos.x = Math.max(8, Math.min(72, hero.pos.x + 30 * Math.cos angle))
        built.pos.y = Math.max(7, Math.min(68, hero.pos.y + 30 * Math.sin angle))
      built.hasMoved = true

  setup: ->
    @didSetup = true
    p.isAttackable = false for p in @world.thangs when p.type is "palisade"
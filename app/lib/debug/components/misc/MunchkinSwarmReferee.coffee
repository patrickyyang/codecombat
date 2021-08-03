Component = require 'lib/world/component'

module.exports = class MunchkinSwarmReferee extends Component
  @className: 'MunchkinSwarmReferee'
  chooseAction: ->
    @setup() unless @didSetup
    shouldHaveSpawned = @world.age * 0.5 - 1
    wave = Math.max 0, Math.floor(@world.age / 12)
    shouldHaveSpawned += 5 * wave
    if shouldHaveSpawned > @built.length and @world.age < 40
      buildType = if @world.rand.randf() < 0.5 then 'ogre-munchkin-m' else 'ogre-munchkin-f'
      @build buildType
      built = @performBuild()
      built.pos.x = 40
      built.pos.y = 36
      while built.pos.distance({x: 40, y: 36}) < 15
        built.pos.x = 8 + @world.rand.randf() * 64
        built.pos.y = 8 + @world.rand.randf() * 52
      built.hasMoved = true
    living = (t for t in @built when t.health > 0)
    brack = @world.getThangByID("Brack")
    living.push brack if brack.health > 0
    hero = @world.getThangByID 'Hero Placeholder'
    if hero.distance({x: 40, y: 36}) > 10
      @orderAttack t for t in living
    else if living.length < 13
      @orderEvasion t, living.length for t in living
    else
      @orderAttack t for t in living
      
  setup: ->
    @didSetup = true
    hero = @world.getThangByID 'Hero Placeholder'
    # Make sure hero can cleave munchkins "hidden" behind the chest
    hero.seesThroughWalls = true

  orderEvasion: (thang, livingCount) ->
    return if thang.hasAttackOrders and livingCount > 5
    hero = @world.getThangByID 'Hero Placeholder'
    awayFromHero = hero.pos.copy().add(thang.pos.copy().subtract(hero.pos).normalize().multiply(15))
    awayFromHero.x += 2 * Math.cos(@world.age)
    awayFromHero.y += 2 * Math.sin(@world.age)
    thang.move awayFromHero
    
  orderAttack: (thang) ->
    thang.hasAttackOrders = true
    hero = @world.getThangByID 'Hero Placeholder'
    thang.attack hero

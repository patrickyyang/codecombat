Component = require 'lib/world/component'

Rectangle = require 'lib/world/rectangle'

module.exports = class CavernSurvival2Referee extends Component
  @className: 'CavernSurvival2Referee'
  
  
  setUp: ->
    hero = @world.getThangByID 'Hero Placeholder'
    posX = 30 + @world.rand.randf() * 40
    posY = 31 + @world.rand.randf() * 75
    hero.teleportXY posX, posY
    hero2 = @world.getThangByID 'Hero Placeholder 1'
    posX2 = 160 - posX
    hero2.teleportXY posX2, posY
    @didSetUp = true
    for spikes in @findHazards() when spikes.type is 'spike-trap'
      spikes.attackDamage = 500
      spikes.attackRange = 4
      spikes.attackMass = 1000

  chooseAction: ->
    @setUp() unless @didSetUp
    spawnRate = 0.333 + @world.age / 120  # Range from 0.333 to 1.333 enemies per second on each side
    shouldHaveSpawned = 3 + spawnRate * @world.age
    if shouldHaveSpawned > @built.length / 2
      spawnChances = [
        [0, 'ogre-munchkin-f']
        [15, 'ogre-munchkin-m']
        [30, 'ogre-thrower']
        [49, 'ogre-m']
        [58, 'ogre-f']
        [65, 'health-potion-large']
        [67, 'ogre-fangrider']
        [76, 'ogre-shaman']
        [85, 'ogre-brawler']
        [90, 'bear-trap']
        [95, 'ogre-headhunter']
      ]
      r = @world.rand.randf()
      n = 100 * Math.pow r, 75 / (@world.age + 1)
      for [spawnChance, type] in spawnChances
        if n >= spawnChance
          buildType = type
        else
          break
      fences = (t for t in @world.thangs when t.spriteName is 'Fence Wall' and t.exists)
      for fence in fences when @world.rand.randf() < 0.2  # Fences vanish sometimes.
        fence.stateless = false
        fence.setExists false
        @say? 'Begone, fence!'
      #console.log 'found', n, 'which is', buildType, 'from', r
      @build buildType
      built = @performBuild()
      built.team = 'neutral'
      built.pos.x = 30 + @world.rand.randf() * 40
      built.pos.y = 31 + @world.rand.randf() * 75
      if built.move
        built.hasMoved = true
      else
        built.addTrackedProperties ['pos', 'Vector']
        built.keepTrackedProperty 'pos'
      @build buildType
      built2 = @performBuild()
      built2.team = 'neutral'
      built2.pos.x = 160 - built.pos.x
      built2.pos.y = built.pos.y
      built2.hasMoved = true
      if built2.move
        built2.hasMoved = true
      else
        built2.addTrackedProperties ['pos', 'Vector']
        built2.keepTrackedProperty 'pos'

    for heroID in ['Hero Placeholder', 'Hero Placeholder 1']
      hero = @world.getThangByID heroID
      if hero.sayMessage is "You'll never defeat me!" and not hero.nerfed
        hero.nerfed = true
        hero.health = hero.maxHealth = hero.maxHealth * 0.75
        hero.maxSpeed *= 0.75
      #@westRect ?= new Rectangle(38, 66, 70, 126)
      @westRect ?= new Rectangle(50, 66, 44, 81)
      #@eastRect ?= new Rectangle(122, 66, 70, 126)
      @eastRect ?= new Rectangle(110, 66, 44, 81)
      @midRect ?= new Rectangle(79, 69, 18, 26)
      unless _.find [@westRect, @eastRect, @midRect], ((r) -> r.containsPoint hero.pos)
          @say 'Back where you belong!'
          home = if heroID is 'Hero Placeholder' then @westRect else @eastRect
          hero.pos = home.getPos()

    for minion in @built when minion.action is 'idle' and minion.health > 0
      # Don't let any fences fool the minions from attacking the dastardly hero
      hero = @world.getThangByID (if minion.pos.x < 80 then 'Hero Placeholder' else 'Hero Placeholder 1')
      minion.attack hero
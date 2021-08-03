Component = require 'lib/world/component'

module.exports = class TreasureGroveReferee extends Component
  @className: 'TreasureGroveReferee'
  chooseAction: ->
    if (@world.age + 6) > (@built.length / 2)
      spawnChances = [
        [0, 'bronze']
        [65, 'silver']
        [85, 'gold']
      ]
      r = @world.rand.randf()
      n = 100 * Math.pow r, 45 / (@world.age + 1)
      for [spawnChance, type] in spawnChances
        if n >= spawnChance
          buildType = type
        else
          break
      @build buildType
      built = @performBuild()
      #console.log 'found', n, 'which is', buildType, 'from', r, 'and have built', @built.length
      built.pos.x = 10 + @world.rand.randf() * 62
      built.pos.y = 10 + @world.rand.randf() * 46
      built.addTrackedProperties ['pos', 'Vector']
      built.keepTrackedProperty 'pos'

    @reviveTimeouts ?= {}
    for heroID in _.keys(@reviveTimeouts)
      @reviveTimeouts[heroID] -= @world.dt
      if @reviveTimeouts[heroID] <= 0
        hero = @world.getThangByID heroID
        effect.timeSinceStart = 9001 for effect in hero.effects when effect.name is 'undead'
        hero.updateEffects()
        hero.revive()
        hero.health = hero.maxHealth
        hero.pos.x = 10 + @world.rand.randf() * 62
        hero.pos.y = 10 + @world.rand.randf() * 46
        hero.pos.z = 60
        hero.velocity.z = -30
        delete @reviveTimeouts[heroID]
      
    for heroID in ['Hero Placeholder', 'Hero Placeholder 1']
      hero = @world.getThangByID heroID
      if hero.sayMessage is "You'll never defeat me!" and not hero.nerfed
        hero.nerfed = true
        hero.health = hero.maxHealth = hero.maxHealth / 4
        hero.maxSpeed *= 0.75
      if (hero.health <= 0 or hero.hasEffect('undead')) and not @reviveTimeouts[heroID]
        @reviveTimeouts[heroID] = 5
        oldGold = @world.getSystem('Inventory').goldForTeam hero.team
        @world.getSystem('Inventory').subtractGoldForTeam hero.team, Math.floor(oldGold / 3)

    unless @winnerPicked
      if @world.getSystem('Inventory').teamGold.ogres.gold >= 100
        @setGoalState 'ogre-gold', 'success'
        @winnerPicked = true
      else if @world.getSystem('Inventory').teamGold.humans.gold >= 100
        @setGoalState 'human-gold', 'success'
        @winnerPicked = true

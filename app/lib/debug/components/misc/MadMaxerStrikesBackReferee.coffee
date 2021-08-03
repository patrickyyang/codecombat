Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class MadMaxerStrikesBackReferee extends Component
  @className: 'MadMaxerStrikesBackReferee'
  chooseAction: ->
    @spawnRing()

  setUpLevel: ->
    @wave = 0
    @spawnTime = 0
    @spawnCenter = new Vector(@hero.pos.x, @hero.pos.y)
    @spawnRadius = 10
    @victoryOgres = false

  spawnRing: ->
    return if @world.age > 25
    return if @world.age < @spawnTime
    @spawnTime = @world.age + 10
    n = 3 + @wave

    # align the ring so that the first/biggest mob is nearest to the player.
    delta = new Vector(@hero.pos.x - @spawnCenter.x, @hero.pos.y - @spawnCenter.y)
    aoffset = Math.atan2(delta.y, delta.x)
    #aoffset -= ((Math.PI * 2)/n) * .40
    
    sf = (@hero.maxHealth + Math.pow(@hero.maxSpeed, 3)) / 1200
    if @hero.attackRange > @spawnRadius # Run speed doesn't matter for ranged heroes.
      sf = @hero.maxHealth / 360
    @minDamage = 0.5 * sf
    @maxDamage = 2.0 * sf

    for i in [0...n]
      r = @spawnRadius * (1.0 + (.05 * i)) # subtly spiral out so that earlier (bigger) mobs are closer
      a = (2 * Math.PI) / n * i + aoffset
      x = @spawnCenter.x + r * Math.cos(a)
      y = @spawnCenter.y + r * Math.sin(a)
      @spawnOne(i/n, x, y)
    ++@wave

  spawnOne: (t, x, y) ->
    mob = @instabuild 'ogre-thrower', x, y
    mob.scaleFactor = @map(t, 1, 0, 0.7, 1.4) # biggest to smallest
    mob.attackDamage *= @map(t, 0, 1, @minDamage, @maxDamage) # smaller mobs do more damage
    mob.maxHealth *= @map(t, 1, 0, 0.5, 1.0)
    mob.health = mob.maxHealth
    mob.addTrackedProperties ['attackDamage', 'number'], ['maxHealth', 'number']
    mob.keepTrackedProperty 'scaleFactor'
    mob.keepTrackedProperty 'attackDamage'
    mob.keepTrackedProperty 'maxHealth'

  map: (t, imin, imax, omin, omax) ->
    return omin if imax == imin
    omin + omax * ((t - imin) / (imax - imin))

  checkVictory: ->
    return if @victoryOgres
    return unless @world.age > 25
    livingOgres = (t for t in @world.thangs when t.team is 'ogres' and t.health > 0)
    if livingOgres.length == 0
      @victoryOgres = true
      @setGoalState 'ogres-die-for-real', 'success'
      @world.endWorld true, 1

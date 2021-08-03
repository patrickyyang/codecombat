Component = require 'lib/world/component'

Vector = require 'lib/world/vector'
module.exports = class SuicideExplosion extends Component
  @className: 'SuicideExplosion'
  @proximity = false
  @hasExploded = false
  constructor: (config) ->
    super config
    
  update: ->
    nearest = @findNearest(@findEnemies())
    if nearest
      @proximity = true if @distance(nearest) < @triggerRadius
    if (@health <= 0 or @proximity) and not @hasExploded
      if @explosionDelay > 0
        @explosionDelay -= @world.dt
        return 
      @hasExploded = true
      @takeDamage @damage
      args = [parseFloat(@pos.x.toFixed(2)),parseFloat(@pos.y.toFixed(2)),parseFloat(@explosionRadius), @explosionColor]
      @addCurrentEvent "aoe-#{JSON.stringify(args)}"
      targets = if @friendlyFire then @world.getSystem('Combat').attackables else @getEnemies()
      for target in targets
        if(target) and @distance(target, true) <= @explosionRadius
          dir = target.pos.copy().subtract(@pos).normalize()
          dir.z = Math.sin Math.PI / 8
          dir.multiply @explosionMass, true
          if @damageDistribution is 'full'
            target.takeDamage @damage, @, dir
          else if @damageDistribution is 'linear'
            linearDamage = @damage * (@explosionRadius - @distance(target)) / @explosionRadius
            target.takeDamage linearDamage, @, dir

          
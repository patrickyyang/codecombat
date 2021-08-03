Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class CastsSummonUndead extends Component
  @className: 'CastsSummonUndead'

  constructor: (config) ->
    super config
    @_summonUndeadSpell = name: 'summon-undead', cooldown: @cooldown, specificCooldown: @specificCooldown, duration: @duration, count: @count
    delete @count
    delete @duration
    delete @cooldown
    delete @specificCooldown

  attach: (thang) ->
    @skeletonThangType = (@requiredThangTypes ? [])[0]
    thang.requiredThangTypes = (thang.requiredThangTypes ? []).concat(@requiredThangTypes ? [])
    thang.componentsForThangType @skeletonThangType if @skeletonThangType  # Make sure the Components are saved to the world's classMap.
    delete @requiredThangTypes
    super thang
    thang.addSpell @_summonUndeadSpell

  'getTarget_summon-undead': ->
    @getNearestEnemy()  # Only start summoning when we see an enemy

  'perform_summon-undead': ->
    @configureSkeleton() unless @skeletonComponents
    if not @skeletonComponents
      throw new ArgumentError "There was a problem loading the Skeleton Thang Components."

    for i in [0 ... @spells['summon-undead'].count]
      skeleton = @spawn @skeletonSpriteName, @skeletonComponents
      skeleton.keepTrackedProperty 'pos'

      # Find a summon spot that isn't inside an obstacle    
      @aiSystem ?= @world.getSystem "AI"
      angle = @world.rand.randf() * 2 * Math.PI
      distance = @world.rand.randf2 4, 8
      placementAttempts = 8
      while placementAttempts--
        targetPos = new Vector @pos.x + distance * Math.cos(angle), @pos.y + distance * Math.sin(angle)
        break if @aiSystem.isPathClear @pos, targetPos, @, true
        angle += Math.PI / 4
        distance *= 0.8
      
      z = skeleton.pos.z
      skeleton.pos = targetPos
      skeleton.pos.z = z + 1
      skeleton.velocity = new Vector(8, 0, 2).rotate(angle)
      @brake?()

  configureSkeleton: ->
    if @skeletonThangType
      @skeletonComponents = _.cloneDeep @componentsForThangType @skeletonThangType
      @skeletonSpriteName = _.find(@world.thangTypes, original: @skeletonThangType)?.name ? @skeletonThangType
      if @skeletonComponents?.length
        if allied = _.find(@skeletonComponents, (c) -> c[1].team)
          allied[1].team = @team
      else
        console.log @id, "CastsSummonUndead problem: couldn't find Skeleton to summon for type", @skeletonThangType
      
    else
      console.log("Couldn't find skeletonThangType!")
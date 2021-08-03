Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class CastsSummonBurl extends Component
  @className: 'CastsSummonBurl'

  constructor: (config) ->
    super config
    @_summonBurlSpell = name: 'summon-burl', cooldown: @cooldown, specificCooldown: @specificCooldown, duration: @duration, count: @count
    delete @count
    delete @duration
    delete @cooldown
    delete @specificCooldown

  attach: (thang) ->
    @burlThangType = (@requiredThangTypes ? [])[0]
    thang.requiredThangTypes = (thang.requiredThangTypes ? []).concat(@requiredThangTypes ? [])
    thang.componentsForThangType @burlThangType if @burlThangType  # Make sure the Components are saved to the world's classMap.
    delete @requiredThangTypes
    super thang
    thang.addSpell @_summonBurlSpell

  'getTarget_summon-burl': ->
    @getNearestEnemy()  # Only start summoning when we see an enemy

  'perform_summon-burl': ->
    @configureBurl() unless @burlComponents
    if not @burlComponents
      throw new ArgumentError "There was a problem loading the burl Thang Components."

    for i in [0 ... @spells['summon-burl'].count]
      burl = @spawn @burlSpriteName, @burlComponents
      burl.keepTrackedProperty 'pos'

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
      
      z = burl.pos.z
      burl.pos = targetPos
      burl.pos.z = z + 1
      burl.velocity = new Vector(8, 0, 2).rotate(angle)
      @brake?()

  configureBurl: ->
    if @burlThangType
      @burlComponents = _.cloneDeep @componentsForThangType @burlThangType
      @burlSpriteName = _.find(@world.thangTypes, original: @burlThangType)?.name ? @burlThangType
      if @burlComponents?.length
        if allied = _.find(@burlComponents, (c) -> c[1].team)
          allied[1].team = @team
      else
        console.log @id, "CastsSummonBurl problem: couldn't find burl to summon for type", @burlThangType
      
    else
      console.log("Couldn't find burlThangType!")
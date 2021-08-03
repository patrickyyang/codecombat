Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class CastsGoldstorm extends Component
  @className: 'CastsGoldstorm'

  constructor: (config) ->
    super config
    @_goldstormSpell = name: 'goldstorm', cooldown: @cooldown, specificCooldown: @specificCooldown, amount: @amount
    delete @amount
    delete @cooldown
    delete @specificCooldown

  attach: (thang) ->
    @goldCloudThangType = (@requiredThangTypes ? [])[0]
    thang.requiredThangTypes = (thang.requiredThangTypes ? []).concat(@requiredThangTypes ? [])
    thang.componentsForThangType @goldCloudThangType if @goldCloudThangType  # Make sure the Components are saved to the world's classMap.
    delete @requiredThangTypes
    super thang
    thang.addSpell @_goldstormSpell
    
  perform_goldstorm: ->
    @configureGoldCloud() unless @goldCloudComponents
    return unless @goldCloudComponents
    @lastGoldCloudSpawned = @spawn @goldCloudSpriteName, @goldCloudComponents
    @lastGoldCloudSpawned?.rainCount = Math.ceil @spells.goldstorm.amount / 3

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
    
    z = @lastGoldCloudSpawned.pos.z
    @lastGoldCloudSpawned.pos = targetPos
    @lastGoldCloudSpawned.pos.z = z
    @lastGoldCloudSpawned.velocity = new Vector(1, 0, 0).rotate(angle).multiply @lastGoldCloudSpawned.velocity.magnitude()
    @brake?()
    @lastGoldCloudSpawned

  configureGoldCloud: ->
    if @goldCloudThangType
      @goldCloudComponents = _.cloneDeep @componentsForThangType @goldCloudThangType
      @goldCloudSpriteName = _.find(@world.thangTypes, original: @goldCloudThangType)?.name ? @goldCloudThangType
    if @goldCloudComponents?.length
      if allied = _.find(@goldCloudComponents, (c) -> c[1].team)
        allied[1].team = @team
    else
      console.log @id, "CastsGoldstorm problem: couldn't find cloud to spawn for type", @goldCloudThangType

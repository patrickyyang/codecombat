Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class CastsSummonFangrider extends Component
  @className: 'CastsSummonFangrider'

  constructor: (config) ->
    super config
    @_summonFangriderSpell = name: 'summon-fangrider', cooldown: @cooldown, specificCooldown: @specificCooldown, duration: @duration, count: @count
    delete @count
    delete @duration
    delete @cooldown
    delete @specificCooldown

  attach: (thang) ->
    @fangriderThangType = (@requiredThangTypes ? [])[0]
    thang.requiredThangTypes = (thang.requiredThangTypes ? []).concat(@requiredThangTypes ? [])
    thang.componentsForThangType @fangriderThangType if @fangriderThangType  # Make sure the Components are saved to the world's classMap.
    delete @requiredThangTypes
    super thang
    thang.addSpell @_summonFangriderSpell

  'getTarget_summon-fangrider': ->
    @getNearestEnemy()  # Only start summoning when we see an enemy

  'perform_summon-fangrider': ->
    @configureFangrider() unless @fangriderComponents
    if not @fangriderComponents
      throw new ArgumentError "There was a problem loading the Fangrider Thang Components."

    for i in [0 ... @spells['summon-fangrider'].count]
      fangrider = @spawn @fangriderSpriteName, @fangriderComponents
      fangrider.keepTrackedProperty 'pos'

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
      
      z = fangrider.pos.z
      fangrider.pos = targetPos
      fangrider.pos.z = z
      @brake?()

  configureFangrider: ->
    if @fangriderThangType
      @fangriderComponents = _.cloneDeep @componentsForThangType @fangriderThangType
      @fangriderSpriteName = _.find(@world.thangTypes, original: @fangriderThangType)?.name ? @fangriderThangType
      if @fangriderComponents?.length
        if allied = _.find(@fangriderComponents, (c) -> c[1].team)
          allied[1].team = @team
      else
        console.log @id, "CastsSummonFangrider problem: couldn't find fangrider to summon for type", @fangriderThangType
      
    else
      console.log("Couldn't find fangriderThangType!")
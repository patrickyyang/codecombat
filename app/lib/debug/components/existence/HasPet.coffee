Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class HasPet extends Component
  @className: 'HasPet'
  
  attach: (thang) ->
    unless @petThangType = (@requiredThangTypes ? [])[0]
      console.error thang.id, "HasPet problem: pet requiredThangTypes is not configured."
      delete @requiredThangTypes
      return super thang
    
    thang.requiredThangTypes = (thang.requiredThangTypes ? []).concat(@requiredThangTypes ? [])
    delete @requiredThangTypes
    super thang

  postEquip: ->
    return if @pet  # For some reason, this would get called twice.
    @spawnPet()

  spawnPet: ->
    petSpriteName = _.find(@world.thangTypes, original: @petThangType)?.name ? @petThangType
    petComponents = _.cloneDeep @componentsForThangType @petThangType  # Make sure the Components are saved to the world's classMap.
    if petComponents?.length
      if allied = _.find(petComponents, (c) -> c[1].team)
        allied[1].team = @team
        
    aiSystem = @world.getSystem "AI"
    angle = @world.rand.randf() * 2 * Math.PI
    placementAttempts = 8
    while placementAttempts--
      targetPos = new Vector @pos.x + 3 * Math.cos(angle), @pos.y + 3 * Math.sin(angle)
      break if aiSystem.isPathClear @pos, targetPos, @, true
      angle += Math.PI / 4
        
    @pet = @spawn petSpriteName, petComponents
    @pet.pos.x = targetPos.x
    @pet.pos.y = targetPos.y
    if @pet.move
      @pet.hasMoved = true
    else
      @pet.addTrackedProperties ['pos', 'Vector']
      @pet.keepTrackedProperty 'pos'

    @pet.commander = @
    # Pets aren't attackable so we need to replace "attackers" when it attacks.
    @pet.attackerReplacement = @
    # Normal commandable units (sometimes?) don't block on actions. Pets should.
    @pet.actionsShouldBlock = true
    @pet.trigger? "spawn"
    
    return unless @getAetherForMethod?('plan')
    
    if aether = @getAetherForMethod?('plan')
      aether.addGlobal? 'pet', @pet


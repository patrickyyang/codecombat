Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class GrowsFlowers extends Component
  @className: 'GrowsFlowers'

  attach: (thang) ->
    super thang
    thang.lastFlowerTime = -1
    thang.flowerDistance = @flowerDistance
    thang.flowerCooldown = @flowerCooldown
    thang.flowerDecay = @flowerDecay
    thang.doBuildFlowers = true
    thang.growFlowerColor = "random"
    thang.flowersBuilt = []
    thang.flowerColorNames = [
      "pink"
      "red"
      "blue"
      "purple"
      "yellow"
      "white"
      "random"
    ]
    
    thang.flowerTypeMap =
      'Flower 1': '54e951c8f54ef5794f354ed1'
      'Flower 2': '54e9525ff54ef5794f354ed5'
      'Flower 3': '54e95293f54ef5794f354ed9'
      'Flower 4': '54e952b7f54ef5794f354edd'
      'Flower 5': '54e952daf54ef5794f354ee1'
      'Flower 6': '54e95308f54ef5794f354ee5'
      'Flower 7': '54e9532ff54ef5794f354ee9'
      'Flower 8': '54e9534ef54ef5794f354eed'
    
    thang.colorBuildTypes = 
      "pink"  : ["Flower 1"]
      "red"   : ["Flower 2", "Flower 5"]
      "blue"  : ["Flower 3", "Flower 8"]
      "purple": ["Flower 4"]
      "yellow": ["Flower 6"]
      "white" : ["Flower 7"]
      "random": ["Flower 1","Flower 2","Flower 3","Flower 4","Flower 5","Flower 6","Flower 7","Flower 8"]

    thang.requiredThangTypes = (thang.requiredThangTypes ? []).concat(@requiredThangTypes ? [])
    for flowerType in thang.requiredThangTypes
      thang.componentsForThangType flowerType  # Make sure the Components are saved to the world's classMap.
    delete @requiredThangTypes

  update: ->
    @doDecayFlower()
    return if not @doBuildFlowers
    @lastFlowerPos ?= @pos.copy()
    return unless @world.age > @lastFlowerTime + @flowerCooldown
    if @distance(@lastFlowerPos) > @flowerDistance
      @buildFlower()
      
  buildFlower: ->
    buildTypes = @colorBuildTypes[@growFlowerColor]
    rand = @world.rand.rand(buildTypes.length)
    buildType = buildTypes[rand]
    {flowerSpriteName, flowerComponents} = @configureFlower(buildType)
    if not flowerComponents
      throw new ArgumentError "There was a problem loading the flower Thang Components for #{buildType}."
    flower = @spawn flowerSpriteName, flowerComponents
    flowerZ = flower.pos.z
    flower.pos = @pos.copy()
    flower.pos.z = flowerZ
    flower.decayTime = @world.age + @flowerDecay
    flower.addTrackedProperties ['pos', 'Vector']
    flower.keepTrackedProperty 'pos'
    @lastFlowerTime = @world.age
    @lastFlowerPos = @pos.copy()
    @flowersBuilt.push flower

  doDecayFlower: ->
    return unless @flowersBuilt.length > 0 and (@world.age >= @flowersBuilt[0].decayTime)
    flower = @flowersBuilt.shift()
    flower.setExists false
    
  toggleFlowers: (grow) ->
    if not _.isBoolean(grow) and typeof(grow) isnt 'undefined'
      throw new ArgumentError "toggleFlowers argument should be empty or boolean.", "toggleFlowers", "grow", "boolean", grow
    if typeof(grow) is 'undefined'
      @doBuildFlowers = !@doBuildFlowers
    else
      @doBuildFlowers = grow
    
  startFlowers: ->
    @toggleFlowers true
    
  stopFlowers: ->
    @toggleFlowers false
    
  setFlowerColor: (color) ->
    unless color in @flowerColorNames
      throw new ArgumentError "Requires a color; one of [\"#{@flowerColorNames.join('\", \"')}\"]", "flowerColor", "color", "string", color
    @growFlowerColor = color
    
  configureFlower: (flowerThangType) ->
    return console.log "What flower type?" unless flowerThangType
    @flowerComponentsCache ?= {}
    return cached if cached = @flowerComponentsCache[flowerThangType]
    flowerComponents = _.cloneDeep @componentsForThangType @flowerTypeMap[flowerThangType]
    flowerSpriteName = _.find(@world.thangTypes, original: flowerThangType)?.name ? flowerThangType
    return @flowerComponentsCache[flowerThangType] = flowerComponents: flowerComponents, flowerSpriteName: flowerSpriteName
    
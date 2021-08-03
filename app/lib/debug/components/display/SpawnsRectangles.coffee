Component = require 'lib/world/component'

Vector = require 'lib/world/vector'

module.exports = class SpawnsRectangles extends Component
  @className: 'SpawnsRectangles'
  constructor: (config) ->
    super config
    @_rectAction = name: 'addRect', cooldown: 1, specificCooldown: 2
    
  attach: (thang) ->
    super thang
    thang.spawnedRectangles = []
    thang.addActions @_rectAction

  addRect: (x, y, width, height) ->
    #console.log(x, y, width, height);
    x = (x * 4)
    y = ((y + height) * 4)
    width *= 4
    height *= 4
    #console.log(x, y, width, height);
    rectangleThang = @world.getThangByID @rectangleThangID
    unless rectangleThang
      console.log @id, "SpawnsRectangles problem: couldn't find rectangle template for ID", @rectangleThangID
      return
    rectangleThang.setExists false  # it's just the template
    @rectangleSpriteName = rectangleThang.spriteName
    @rectangleComponents = _.cloneDeep rectangleThang.components
    return unless @rectangleSpriteName
    rect = @spawn @rectangleSpriteName, @rectangleComponents
    rect.pos.x = x + width / 2;
    rect.pos.y = y - height / 2;
    rect.width = width
    rect.height = height
    rect.scaleFactorX = 1 / 5 * width;
    rect.scaleFactorY = 1 / 6.7 * height;
    rect.keepTrackedProperty 'scaleFactorX'
    rect.keepTrackedProperty 'scaleFactorY'
    rect.addTrackedProperties ['pos', 'Vector'], ['width', 'number'], ['height', 'number']
    rect.keepTrackedProperty 'pos'
    rect.keepTrackedProperty 'width'
    rect.keepTrackedProperty 'height'
    @spawnedRectangles.push rect
    rect.addCurrentEvent? 'spawned'
    # Have rectangles "pick up" coins
    for thang in @world.thangs when thang.spriteName is 'Coin'
      if rect.contains thang
        if thang.rectArray is undefined or thang.rectArray is null
          thang.rectArray = []
        thang.rectArray.push(rect.id)
        thang.setExists false
        xPos = (thang.pos.x - 2) / 4
        yPos = (thang.pos.y - 2) / 4
        if @navGrid?
          @navGrid[xPos][yPos] = "Rectangle"
    rect

  removeRectAt: (x, y) ->
    for rect in @spawnedRectangles
      if rect.contains {pos:new Vector(x, y)}
        rect.addCurrentEvent? 'removed'
        for thang in @world.thangs when not thang.exists and thang.spriteName is 'Coin'
          if thang.rectArray? and thang.rectArray.indexOf(rect.id) isnt -1
            thang.rectArray.splice(thang.rectArray.indexOf(rect.id), 1)
            if thang.rectArray.length is 0
              thang.setExists true
              xPos = (thang.pos.x - 2) / 4
              yPos = (thang.pos.y - 2) / 4
              if @navGrid?
                @navGrid[xPos][yPos] = "Coin"
        rect.setExists false
        @spawnedRectangles = _.without @spawnedRectangles, rect
        break
    rect
    
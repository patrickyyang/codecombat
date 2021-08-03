Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class GameEnvironment extends Component
  @className: 'GameEnvironment'
  
  MAZE_MAGIC_SEED: 1999
  BORDER_MAGIC_SEED: 2999
  DECOR_MAGIC_SEED: 3999
  SPAWN_MAGIC_SEED: 4999
  BORDER_EXITS: [0, 2]
  MAX_SEED: 400
  FIELD_SIZE: new Vector(80, 68)
  STEP: 8
  SHIFT: 4
  
  constructor: (config) ->
    super(config)
    @gameBounds = null
    @gameBoundsType = "none"
    @initSeed = 0
  
  setSeed: (seed, maxSeed, magicSeed) ->
    @initSeed = @world.rand.seed
    unless _.isNumber seed
      throw new ArgumentError "The seed should be an integer between 0 and #{MAX_SEED}", "spawnMaze", "seed", "number", seed
    seed = Math.floor seed
    seed *= magicSeed
    seed = seed % maxSeed
    @world.rand.setSeed(seed)
    # Warm up randomness :-)
    for i in [0...seed]
      @world.rand.rand 10
  
  resetSeed: ->
    @world.rand.setSeed(@initSeed)
  
  isSomethingNear: (pos, distance) ->
    ds = distance * distance
    for th in @world.thangs when th.exists and th.collides and th.originalCollisionCategory isnt "none"
      if th.distanceSquared?(pos) <= ds
        return true
    return false
  
  # Generate a  9x9 maze of forest tiles
  # The maze should be the same for the same seed
  spawnMaze: (tileType="forest", seed=1) ->
    # for the legacy mazes where seed argument is the first
    isLegacy = false
    if _.isNumber(tileType)
      seed = tileType
      tileType = "forest"
      isLegacy = true
    @setSeed(seed, @MAX_SEED, @MAZE_MAGIC_SEED)

    # Maze is 9x9 forest tiles
    maze = []
    for row in [0..8]
      maze[row] = []
      maze[row].push(1) for col in [0..8]
      
    # random start: odd row/column, not the outsides
    row = 1 + @world.rand.rand 8
    while (row % 2) is 0
      row = 1 + @world.rand.rand 8
    col = 1 + @world.rand.rand 8
    while (col % 2) is 0
      col = 1 + @world.rand.rand 8
      
    maze[row][col] = 0

    @generateMaze = (r, c) ->
      # Directions
      dirs = ["up", "down", "left", "right"]
      dirs = (@world.rand.shuffleCompat ? _.shuffle)(dirs)

      doors = []
      for dir in dirs
        switch dir
          when "up"
            continue if (r + 2) >= 8
            if maze[r + 2][c]
              maze[r + 2][c] = 0
              maze[r + 1][c] = 0
              @generateMaze(r + 2, c)
            else
              doors.push [r + 1, c]
          when "down"
            continue if (r - 2) <= 0
            if maze[r - 2][c]
              maze[r - 2][c] = 0
              maze[r - 1][c] = 0
              @generateMaze(r - 2, c)
            else
              doors.push [r - 1,c]
          when "right"
            continue if (c + 2) >= 8
            if maze[r][c + 2]
              maze[r][c + 2] = 0
              maze[r][c + 1] = 0
              @generateMaze(r, c + 2)
            else
              doors.push [r, c + 1]
          when "left"
            continue if (c - 2) <= 0
            if maze[r][c - 2]
              maze[r][c - 2] = 0
              maze[r][c - 1] = 0
              @generateMaze(r, c - 2)
            else
              doors.push [r, c - 1]
      
      # Maybe open a "door" for more variety
      doors = (@world.rand.shuffleCompat ? _.shuffle)(doors)
      door = doors[0]
      maze[door[0]][door[1]] = 0 if @world.rand.rand 2

    @generateMaze(row, col)
    # Place Maze
    unless isLegacy
      maze.push([])
      maze[9].push(1) for row in [0..8]
    for row in [0...maze.length]
      for col in [0...maze[row].length]
        continue unless maze[row][col]
        pos = new Vector((row * 8) + 4, (col * 8) + 4)
        shouldBuild = true
        unless isLegacy
          if @isSomethingNear(pos, 4)
            shouldBuild = false
        @spawnXY(tileType, pos.x, pos.y) if shouldBuild
    @resetSeed()
    @spawnedMaze = seed
  
  spawnBorders: (terrainType, seed=0) ->
    @spawnLeftBorder(terrainType, seed)
    @spawnRightBorder(terrainType, seed)
    @spawnTopBorder(terrainType, seed)
    @spawnBottomBorder(terrainType, seed)
  
  spawnLeftBorder: (terrainType, seed=0) ->
    @spawnDirBorder(terrainType, seed, "left")
  
  spawnRightBorder: (terrainType, seed=0) ->
    @spawnDirBorder(terrainType, seed, "right")
  
  spawnTopBorder: (terrainType, seed=0) ->
    @spawnDirBorder(terrainType, seed, "top")
  
  spawnBottomBorder: (terrainType, seed=0) ->
    @spawnDirBorder(terrainType, seed, "bottom")
  
  
  spawnDirBorder: (terrainType, seed, dir) ->
    tileType = @terrainTiles[terrainType] or terrainType
    unless _.isNumber seed
      throw new ArgumentError "The seed should be an integer between 0 and #{MAX_SEED}", "spawnMaze", "seed", "number", seed
    @setSeed(seed, @MAX_SEED, @BORDER_MAGIC_SEED)
    exits = seed and @world.rand.rand2(@BORDER_EXITS[0], @BORDER_EXITS[1])
    walls = []
    if dir is "left"
      for y in [@SHIFT..@FIELD_SIZE.y] by @STEP  
        walls.push(Vector(@SHIFT, y))
    if dir is "right"
      for y in [@SHIFT..@FIELD_SIZE.y] by @STEP  
        walls.push(Vector(@FIELD_SIZE.x - @SHIFT, y))
    if dir is "top"
      for x in [@SHIFT..@FIELD_SIZE.x] by @STEP  
        walls.push(Vector(x, @FIELD_SIZE.y))
    if dir is "bottom"
      for x in [@SHIFT..@FIELD_SIZE.x] by @STEP  
        walls.push(Vector(x, @SHIFT))
    @world.rand.shuffle(walls)
    for w in walls.splice(exits)
      if not @isSomethingNear(w, 3)
        @spawnXY(tileType, w.x, w.y)
    @resetSeed()
    
  setBounds: (boundType) ->
    if boundType not in ["none", "wall", "warp"]
      throw new ArgumentError "The bounds should be on of these types: 'none', 'wall', 'warp'", "setBounds", "boundType", "string", boundType
    if @gameBounds
      @removeBounds()
    @gameBoundsType = boundType
    if boundType is "wall"
      left = @spawnXY("obstacle", -2, 34)
      left.width = 4
      left.height = 68
      right = @spawnXY("obstacle", 82, 34)
      right.width = 4
      right.height = 68
      up = @spawnXY("obstacle", 40, -2)
      up.width = 80
      up.height = 4
      down = @spawnXY("obstacle", 40, 70)
      down.width = 80
      down.height = 4
      @gameBounds = [left, up, right, down]
      for bound in @gameBounds
        bound.destroyBody()
        bound.createBodyDef()
        bound.createBody()
        bound.destructable = false
    
    
  checkWrapBounds: ->    
    @movingSystem ?= @world.getSystem("Movement")
    for m in @movingSystem.movers when m.exists and m.pos and m isnt @
      if 0 <= m.pos.x <= 80 and 0 <= m.pos.y <= 68
        continue
      oldPos = m.pos.copy()
      m.trigger?("exit", {target: m, pos: oldPos})
      if @gameBoundsType is "warp"
        if m.pos.x > 82
          m.pos.x = 2
        else if m.pos.x < -2
          m.pos.x = 78
        else if m.pos.y > 70
          m.pos.y = 2
        else if m.pos.y < -2
          m.pos.y = 66
      
  removeBounds: ->
  
  
  spawnDecorations: (terrainType, seed) ->
    seed = @world.rand.rand2(0, 9999) if not seed?
    if terrainType not in ["forest", "desert", "glacier", "mountain"]
      throw new ArgumentError 'The terrain type should be on of these types: "forest", "desert", "glacier", "mountain"', "spawnDecorations", "terrainType", "string", terrainType
    decorationData = @terrainDecorations[terrainType]
    @setSeed(seed, @MAX_SEED, @DECOR_MAGIC_SEED)
    sizeN = Math.ceil(Math.sqrt(decorationData.numberOfCollidables))
    sizeX = (72 - 8) / sizeN
    sizeY = (60 - 8) / sizeN
    
    # @world.rand.shuffle(decorationSet)
    # sizeN = Math.ceil(Math.sqrt(decorationSet.length))
    # sizeX = (72 - 8) / sizeN
    # sizeY = (60 - 8) / sizeN
    # index = 0
    for xs in [8...72] by sizeX
      for ys in [8...60] by sizeY
        decoration = @world.rand.choice(decorationData.collidables)
        x = xs + sizeX / 2 + @world.rand.randf2(-sizeX, sizeX) / 3
        y = ys + sizeY / 2 + @world.rand.randf2(-sizeY, sizeY) / 3
        @spawnXY(decoration, x, y) #.rotation = @world.rand.choice([0, Math.PI])
    
    for i in [0...decorationData.numberOfNonCollidables]
      @spawnXY(@world.rand.choice(decorationData.nonCollidables), @world.rand.rand2(12, 68), @world.rand.rand2(12, 56))
    @resetSeed()
  
  spawnFloor: (terrainType, seed) ->
    seed = @world.rand.rand2(0, 9999) if not seed?
    if terrainType not in ["forest", "desert", "glacier", "mountain"]
      throw new ArgumentError 'The terrain type should be on of these types: "forest", "desert", "glacier", "mountain"', "spawnDecorations", "terrainType", "string", terrainType
    floorType = @terrainFloors[terrainType]
    @setSeed(seed, @MAX_SEED, @DECOR_MAGIC_SEED)
    for th in @world.thangs when th.isLand
      th.setExists(false)
    for x in [0...80] by 20
      for y in [0...68] by 17
        f = @spawnXY(floorType, x + 10, y + 8.5)
    
    @resetSeed()
      
  
  setGravity: (x, y, z=0) ->
    unless _.isNumber x
      throw new ArgumentError "`x` should be a number", "setGravity", "x", "number", x
    unless _.isNumber y
      throw new ArgumentError "`y` should be a number", "setGravity", "y", "number", y
    @world.gravity = @world.getSystem('Movement').gravity = 0
    @world.gameGravity = new Vector(x, y, z)
    @world.gameGravityDt = @world.gameGravity.copy().multiply(@world.dt, true)
    
  applyGravity: ->
    @movingSystem ?= @world.getSystem("Movement")
    for m in @movingSystem.movers when not m.ignoreGravity
      if m._jumpVector
        m.velocity.subtract(m._jumpVector, true)
        m._jumpVector = null
      else
        m.velocity.subtract(@world.gameGravityDt, true)
  
  spawnRandomly: (spawnType, number, seed) ->
    seed = @world.rand.rand2(0, 9999) if not seed?
    # TODO add argument checking
    @setSeed(seed, @MAX_SEED, @SPAWN_MAGIC_SEED)
    for i in [0...number]
      x = @world.rand.rand2(@STEP, @FIELD_SIZE.x - @STEP)
      y = @world.rand.rand2(@STEP, @FIELD_SIZE.y - @STEP)
      @spawnXY(spawnType, x, y)
    @resetSeed()
    
  update: ->
    @checkWrapBounds()
    if @world.gameGravity
      @applyGravity()

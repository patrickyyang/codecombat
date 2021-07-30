System = require 'lib/world/system'
Vector = require 'lib/world/vector'
Rectangle = require 'lib/world/rectangle'
Grid = require 'lib/world/Grid'
{dissectRectangles} = require 'lib/world/world_utils'
box2d = require 'lib/world/box2d'

class AStarNode
  constructor: (@pos, @parent, @g, target) ->
    # Cost function g(): distance taken to get to a vertex
    # Heuristic function h(): simple distance from a vertex to the target
    @h = @pos.distance target
    @f = @g + @h

class AStarNodeSet
  constructor: -> @nodes = []
  add: (node) -> @nodes.push node
  removeFirst: -> @nodes.shift()
  first: -> @nodes[0]
  remove: (node) -> @nodes = _.without @nodes, node
  find: (pos) -> _.find @nodes, (node) -> node.pos.equals pos
  sort: -> @nodes.sort (node1, node2) -> node1.f - node2.f

module.exports = class AI extends System
  constructor: (world, config) ->
    super world, config
    @obstacles = @addRegistry (t) ->
      t.exists and ((t.collides and t.collisionType is 'static' and t.collisionCategory isnt 'none') or t.isLand or t.isHazard) and not t.isMovable and not t.dead
    @grid = null  # constructed on demand
    @navMeshes = {}  # by size in meters
    @graphs = {}
    @pathCache = {}
    @raycastCache = {}
    if box2d
      @obstacleWorld = new box2d.b2World(new box2d.b2Vec2(0, 0), true)
      @obstacleBodies = {}

  start: (thangs) ->
    @onObstaclesChanged()

  onObstaclesChanged: ->
    @grid = null
    @navMeshes = {}
    @graphs = {}
    @pathCache = {}
    @raycastCache = {}
    return unless box2d
    for thangID, body of @obstacleBodies
      thang = @world.getThangByID thangID
      if thang.dead or thang.collisionType isnt 'static' or not thang.exists
        body.SetUserData null
        @obstacleWorld.DestroyBody body
        delete @obstacleBodies[thangID]
    for thang in @obstacles when thang.collides and not @obstacleBodies[thang.id]
      thang.bodyDef.position.x = thang.pos.x
      thang.bodyDef.position.y = thang.pos.y
      body = @obstacleWorld.CreateBody thang.bodyDef
      body.SetUserData thang
      body.CreateFixture thang.fixDef
      @obstacleBodies[thang.id] = body

  update: ->
    # If we have changed obstacles, let's rebuild the mesh.
    if @obstacles.length isnt @lastObstacleCount
      #console.log "Clearing nav mesh, since we now have", @obstacles.length, "and had", @lastObstacleCount if @lastObstacleCount
      @onObstaclesChanged()
      @lastObstacleCount = @obstacles.length
    return hash = 0

  getGraph: (radius) ->
    return @graphs[radius] if @graphs[radius]?
    #console.log 'building graph', radius
    navMesh = @getNavMesh radius
    graph = {}
    
    # find all vertices that touch a rectangle, not just its own corners
    for rect in navMesh
      rect.allVertices = rect.vertices()
      for otherRect in rect.edges
        for vertex in otherRect.vertices()
          if rect.touchesPoint vertex
            rect.allVertices.push vertex
            
    # for any given vertex
    for rect in navMesh
      for vertex in rect.allVertices
        continue if graph[vertex.toString(0)]?
        graph[vertex.toString(0)] = {vertex:vertex, edges: {}}
        rects = _.clone rect.edges
        rects.push rect
        for otherRect in rects
          continue unless otherRect.touchesPoint vertex
          # this vertex can access every other vertex in this rectangle
          for otherVertex in otherRect.allVertices
            continue if vertex.equals otherVertex
            graph[vertex.toString(0)].edges[otherVertex.toString(0)] = otherVertex

    for vertexString, otherVertices of graph
      graph[vertexString].edges = _.values otherVertices.edges
        
    @graphs[radius] = graph
    graph
    
  findPath: (startPos, targetPos, radius) ->
    # Returns null if there's no path and [] if there are no intermediate vertices (they're in the same nav mesh).
    @lastObstacleCount = @obstacles.length unless @lastObstacleCount
    mesh = @getNavMesh radius  # Build the nav mesh for this Thang radius, if we haven't already
    return null unless startRect = @navRectForPoint startPos, mesh
    return null unless targetRect = @navRectForPoint targetPos, mesh
    return [] if startRect is targetRect
    pathCacheKey = startRect.toString() + ' - ' + targetRect.toString() + ' - ' + Math.ceil(radius)
    cached = @pathCache[pathCacheKey]
    if cached
      if cached.length
        cached = cached.slice()
        cached.unshift startPos
        #console.log 'Returning cached path', cached, 'from', startPos, 'to', targetPos, 'for', pathCacheKey if Math.random() < 0.1
      return cached

    # A* adapted from https://github.com/safehammad/coffeescript-astar/blob/master/astar.coffee
    graph = @getGraph radius
    closedSet = new AStarNodeSet
    openSet = new AStarNodeSet
    startingNode = new AStarNode startPos, null, 0, targetPos
    closedSet.add startingNode
    for vertex in startRect.allVertices
      openSet.add new AStarNode vertex, startingNode, vertex.distance(startPos), targetPos
    openSet.sort()

    # run A*
    targetVertices = targetRect.allVertices
    tried = 0
    until _.some (vertex.equals openSet.first().pos for vertex in targetVertices)
      # find lowest cost node, move to closed list
      current = openSet.removeFirst()
      #console.log 'trying', current.pos.toString(0)
      closedSet.add current

      # for each adjacent vertex, update open list
      nextVertices = graph[current.pos.toString(0)].edges
      for vertex in nextVertices
        continue if closedSet.find vertex
        child = new AStarNode vertex, current, current.g + current.pos.distance(vertex), targetPos
        existingNode = openSet.find child.pos
        if existingNode and existingNode.g > child.g
          openSet.remove existingNode
          openSet.add child
        else if not existingNode
          openSet.add child
      openSet.sort()

      # check for failure
      if not openSet.first()
        return @pathCache[pathCacheKey] = []

      return console.error "quitting; coding problem caused infinite loop in A*" if ++tried > 9001

    # shorten the route if possible
    route = (node, points) ->
      points.unshift node.pos
      if node.parent then route(node.parent, points) else points
    path = route openSet.first(), []
    #console.log "got path", path, "from", startPos, startRect, "to", targetPos, targetRect
    if not path.length
      return @pathCache[pathCacheKey] = path
    if false  # if path simplification isn't quite working, can turn off
      @pathCache[pathCacheKey] = path[1 ... path.length]  # only include middle rect points, not start/end points
      return path
    i = 1
    oldPath = _.clone path
    while i < path.length
      if @isPathClear path[i - 1], path[i + 1] ? targetPos, null, true
        path.splice(i, 1)
      else
        ++i
    #console.log "made simplified path", path, "from path", oldPath
    #@pathCache[pathCacheKey] = path[1 ... path.length]  # only include middle rect points, not start points
    return path

  navRectForPoint: (p, mesh, tolerant=true) ->
    return null unless mesh.length
    return rect for rect in mesh when rect.containsPoint p, false
    # We didn't find a mesh, but we're probably just outside one, so let's get the nearest one
    _.min mesh, (rect) -> 
      rect.distanceSquaredToPoint p

  getNavGrid: ->
    return @grid if @grid
    [width, height] = @getNavMeshBounds()
    @grid = new Grid @obstacles, width, height, 0.0
    @grid
    
  isRaycastHit: (fixture, point, normal, fraction) =>
    thang = fixture.GetBody().GetUserData()
    #return -1 if thang is @raycastTargetThang or thang.dead  # version for use with obstacleWorld
    return -1 if thang.collisionType isnt 'static' or thang is @raycastTargetThang or thang.dead or (thang.isHazard and @raycastIgnoresHazards)
    @raycastHit = true
    return 0

  isPathClear: (start, end, targetThang, ignoreHazards) ->
    return false unless box2d?
    
    # Quickly return cached result if there is one (to within nearest meter on start and end)
    sx = Math.round start.x
    sy = Math.round start.y
    ex = Math.round end.x
    ey = Math.round end.y
    if ignoreHazards
      cacheKey = sx + 1e3 * sy + 1e6 * ex + 1e9 * ey  # Single key for point, should work if world size < 1000m
      cacheResult = @raycastCache[cacheKey]
      return cacheResult if cacheResult? and false
    
    if ignoreHazards
      # Quickly return true if they're in the same nav rect
      @storedMesh ?= _.values(@navMeshes)[0]
      if @storedMesh and false
        for rect in @storedMesh
          containsStart = rect.containsPoint start, false
          containsEnd = rect.containsPoint end, false
          return true if containsStart and containsEnd
          break if containsStart or containsEnd

    # Alas, we'll have to resort to a raycast against the obstacles.
    start = new box2d.b2Vec2 sx, sy
    end = new box2d.b2Vec2 ex, ey
    @raycastTargetThang = targetThang
    @raycastHit = false
    @raycastIgnoresHazards = ignoreHazards

    box2dWorld = @world.getSystem('Collision').box2dWorld
    #console.log "Collision System world has", box2dWorld.GetBodyCount(), "bodies."
    #box2dWorld = @obstacleWorld
    #console.log "Obstacle world has", @obstacleWorld.GetBodyCount(), "bodies."
    box2dWorld.RayCast @isRaycastHit, start, end

    @raycasts ?= 0
    @raycasts += 1
    if ignoreHazards
      @raycastCache[cacheKey] = not @raycastHit
    
    return not @raycastHit

  getNavMesh: (radius) ->
    radius = Math.ceil radius
    if navMesh = @navMeshes[radius]
      return navMesh
    debug = false
    [width, height] = @getNavMeshBounds()
    # Grid has 1m resolution, fine for now? Should probably be half of radius.
    grid = new Grid @obstacles, width, height, radius
    rectangles = []
    rectangleCallback = (rect) -> rectangles.push rect
    dissectRectangles grid, rectangleCallback, true, debug
    #console.log "Turned", @obstacles.length, "obstacle Thangs into", rectangles.length, "nav mesh rectangles for radius", radius
    @connectRectangles rectangles
    @navMeshes[radius] = rectangles

  connectRectangles: (rectangles) ->
    # TODO: should probably cache and connect vertices to make the A* way simpler and faster
    for i in [0 ... rectangles.length]
      r1 = rectangles[i]
      r1.edges ?= []
      for j in [i + 1 ... rectangles.length]
        r2 = rectangles[j]
        continue unless r1.touchesRect r2
        (r1.edges ?= []).push r2
        (r2.edges ?= []).push r1

  getNavMeshBounds: ->
    rightmost = _.max @obstacles, (t) -> t.pos.x + t.width / 2
    topmost = _.max @obstacles, (t) -> t.pos.y + t.height / 2
    width = rightmost.pos.x + rightmost.width / 2
    height = topmost.pos.y + topmost.height / 2
    [width, height]
    
  finish: ->
    super(arguments...)
    #console.log 'raycasts:', @raycasts
    @world.navMeshes = @navMeshes
    @world.graphs = @graphs
    @world.addTrackedProperties 'navMeshes', 'graphs'
    return unless box2d
    for thangID, body of @obstacleBodies
      body.SetUserData null
      @obstacleWorld.DestroyBody body
    @obstacleBodies = null
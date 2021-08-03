Component = require 'lib/world/component'

module.exports = class SarvenBrawlReferee extends Component
  @className: 'SarvenBrawlReferee'
  
  setUpLevel: ->
    @patrolOrder = [
      [@rectangles.left, @points.NW]
      [@rectangles.bottom, @points.SW]
      [@rectangles.right, @points.SE]
      [@rectangles.top, @points.NE]
    ]
  
  controlOgres: (ogres) ->
    for ogre in ogres when ogre.action is 'idle' or ogre.targetPos
      if ogre.canSee @hero
        ogre.attack @hero
      else if ogre.action is 'idle' or ogre.distanceSquared(ogre.targetPos) < 25
        # Cycle around counter-clockwise.
        matched = false
        for [rect, edgePoint], i in @patrolOrder
          if rect.containsPoint ogre.pos
            matched = true
            break
        if matched
          [nextRect, nextEdgePoint] = @patrolOrder[(i + 1) % @patrolOrder.length]
          targetPos = nextEdgePoint.copy().add(x: @world.rand.randf2(-8, 8), y: @world.rand.randf2(-8, 8))
          ogre.move targetPos
        else
          ogre.move @hero.pos
    for ogre in ogres when (ogre.action is 'attack' and ogre.target is @hero) or ogre.action is 'move'
      # Attack the nearest enemy we can see (might be different than the hero we can't see)
      enemy = ogre.getNearestEnemy()
      if enemy
        ogre.attack enemy


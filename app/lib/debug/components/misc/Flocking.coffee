Component = require 'lib/world/component'

Vector = require 'lib/world/vector'
#need to figure out way to specify depends on alliance.Allied, targeting.Targets and movement.Moves 
#things to add: 
# -fine-tune default weights
# -respect vision radius
# -avoid enemies
# -attracted to goals?
#based on Reynold's Boids 
module.exports = class Flocking extends Component
  @className: 'Flocking'
  flocks: true

  chooseAction: ->
    velocityVec = @centerOfMass().add(@dontBump().add(@avgVelocity().add(@boundaries().add(@avoidOutsiders().add(@desire()))))).normalize().multiply(@maxSpeed)
    targ = @pos.copy()
    @setTargetPos targ.add(velocityVec)
    @setAction 'move'
    
  centerOfMass: ->
    center = new Vector 0, 0
    allFlockers = (thang for thang in @allAllies when thang.flocks)
    for thang in allFlockers
      center.add(thang.pos)
    center.divide(allFlockers.length)
    return center.subtract(@pos).multiply(@centerOfMassWeight) 
    
  dontBump: ->
    bump = new Vector 0, 0
    allFlockers = (thang for thang in @allAllies when thang.flocks)
    for thang in allFlockers
      if thang isnt @ and @distanceSquared(thang) < 4*Math.max(@width,@height)
        bump.add(@pos.copy().subtract(thang.pos).normalize())
    return bump
    
  avgVelocity: ->
    flockVel = new Vector 0, 0
    allFlockers = (thang for thang in @allAllies when thang.flocks)
    for thang in allFlockers
      flockVel.add(thang.velocity)
    flockVel.divide(@allAllies.length)
    return flockVel.multiply(@commonHeadingWeight) 
    #flockVel
    
  avoidOutsiders: ->
    runaway = new Vector 0, 0
    for thang in @allianceSystem.allAlliedThangs
        if thang isnt @ and thang.superteam isnt @superteam and @distance(thang) < @avoidDistance
          runaway.add(@pos.copy().subtract(thang.pos).normalize().multiply((@avoidDistance-@distance(thang))/@avoidDistance))
    return runaway
    
  #don't bounce off the edges, but try to return as soon as possible if outside
  boundaries: ->
    b = new Vector 0, 0
    if @pos.x < @flockBounds.xMin
      b.x = (@flockBounds.xMin - @pos.x)/2
    if @pos.x > @flockBounds.xMax
      b.x = (@flockBounds.xMax - @pos.x)/2
    if @pos.y < @flockBounds.yMin
      b.y = (@flockBounds.yMin - @pos.y)/2
    if @pos.y > @flockBounds.yMax
      b.y = (@flockBounds.yMax - @pos.y)/2
    return b
    
  #want to go towards certain points
  desire: ->
    d = new Vector 0, 0
    for dp in @desirePoints ? []
      if @pos.distance(dp) < @desireDistance
        d.add(new Vector(dp.x, dp.y).subtract(@pos).normalize().multiply((@desireDistance-@pos.distance(dp))/(30*@desireDistance)))
    return d
    
Component = require 'lib/world/component'

module.exports = class CupboardsOfKithgardReferee extends Component
  @className: 'CupboardsOfKithgardReferee'

  chooseAction: ->
    @setUp() unless @didSetUp
    cupboard = @world.getThangByID 'Cupboard'
    if cupboard.dead
      @hero.snapPoints?.pop()
      @world.setGoalState "injured-cupboard", "success"
    else if cupboard.health < cupboard.maxHealth
      @world.setGoalState "injured-cupboard", "failure"
    @checkCupboard() if not @skeletonActive
    @controlOgres()
    @controlSkeleton() if @skeletonActive

  setUp: ->
    @didSetUp = true
    @skeletonActive = false
    ogre.sawEnemy = false for ogre in @world.thangs when ogre.spriteName is "Ogre M"
    @ogreActivationTime = 1.5
    @hero.findsPaths = false

  checkCupboard: ->
    cupboard = @world.getThangByID 'Cupboard'
    if cupboard.dead
      cupboard.addActions name: 'open_empty', cooldown: 9000
      cupboard.setAction 'open_empty'
      cupboard.act()
      
      if not @skeletonActive
        skel = @world.getThangByID 'Kate'
        skel.health = 500
        skel.maxHealth = 500
        skel.keepTrackedProperty "health"
        skel.keepTrackedProperty "maxHealth"
        skel.pos.x = 43
        skel.pos.y = 29
        skel.hasMoved = true
        skel.say 'Masssssterrrrr...'
        skel.setTargetPos x: 38, y: 30
        skel.setAction 'move'
        skel.act()
        @skeletonActive = true
  
  controlOgres: ->
    if @world.age > @ogreActivationTime
      offset = 0
      for ogre in @world.thangs when ogre.spriteName is "Ogre M" and ogre.exists and not ogre.dead
        ogre.commander = @
        enemy = ogre.getNearestEnemy()
        if @skeletonActive
          skel = @world.getThangByID 'Kate'
          enemy = skel unless skel.dead
        if enemy? and ogre.canSee(enemy) or @skeletonActive
          ogre.stage = 1
          ogre.attack enemy
        else
          if not ogre.stage and ogre.distanceTo({x:74, y:50}) > 1
            ogre.moveXY 74, 50
          else if not ogre.stage and ogre.distanceTo({x:74, y:50}) <= 1
            ogre.stage = 1
          else if ogre.stage? and ogre.stage == 1
            ogre.moveXY 14, 50
          
          
          
  controlSkeleton: ->
    skeleton = @world.getThangByID 'Kate'
    enemy = skeleton.getNearestEnemy()
    if enemy
      skeleton.setTarget enemy
      skeleton.setAction 'attack'
    

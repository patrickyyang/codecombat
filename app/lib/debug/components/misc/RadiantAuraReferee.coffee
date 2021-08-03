Component = require 'lib/world/component'

module.exports = class RadiantAuraReferee extends Component
  @className: 'RadiantAuraReferee'
  chooseAction: ->
    @setUp() unless @didSetUp
    @checkCollections()
    @controlSkeletons()
    @controlKitty()
    
  setUp: ->
    @didSetUp = true
    @hero = @world.getThangByID 'Hero Placeholder'
    @hero.gemsCollected = 0
    @hero.showAura = false
    @kitty = @world.getThangByID 'Kitty'
    @kitty.addActions name: 'trick', cooldown: 1

  # Did the hero collect a gem? Need a beter way to figure this out
  checkCollections: ->
    if @hero.gemsCollected < @hero.collectedThangIDs.length
      @hero.gemsCollected = @hero.collectedThangIDs.length
      @gemWasCollected _.last(@hero.collectedThangIDs)
      
  # Stuff to do when a gem is collected
  gemWasCollected: (gemID) ->
    gem = @world.getThangByID gemID
    gem.wasCollectedBy? @hero

  # Skeletons attack, idle, or flee
  controlSkeletons: ->
    for skeleton in @world.thangs when skeleton.spriteName is "Skeleton"
      enemy = skeleton.getNearestEnemy()
      if enemy 
        if enemy.hasActiveLightstone
          pos = skeleton.pos.copy()
          pos.y -= 1
          skeleton.setTargetPos pos
          skeleton.setAction 'move'
        else 
          skeleton.setTarget enemy
          skeleton.attack(enemy)
      else
        skeleton.setAction 'idle' unless skeleton.target
        
  controlKitty: ->
    return unless @kitty
    @kitty.setAction 'trick'
    
  checkVictory: ->
    return unless @getGoalState('escape') is 'success'
    for skeleton in @world.thangs when skeleton.spriteName is "Skeleton"
      return if skeleton.health > 0 and skeleton.target is @hero
    gems = (g for g in @world.thangs when g.spriteName is 'Lightstone' and (g.exists is true and not g.pickedUpBy))
    @setGoalState 'collect-gems', 'success' unless gems.length
    @world.endWorld true, 0.2

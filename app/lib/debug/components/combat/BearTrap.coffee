Component = require 'lib/world/component'

module.exports = class BearTrap extends Component
  @className: 'BearTrap'
  isHazard: true

  constructor: (config) ->
    super config
    
  attach: (thang) ->
    super thang
    thang.armed = true

  update: ->
    if @triggered() and @rootTimer > 0
      @rootTarget @triggeredBy
      @rootTimer -= @world.dt 

  # This is called by collision.ProximityTrigger
  wasTriggeredBy: (thang) ->
    #console.log @id, 'was triggered by', thang.id, 'at', @world.age
    if not @triggered() and not @immuneToRoot thang and not @dud
      @activateTrap thang

  # Has it been triggered?
  triggered: ->
    return false if @armed
    true

  immuneToRoot: (thang) ->
    immune = false
    immune = true if thang is @builtBy
    immune = true if thang.lastRootTime and @world.age - thang.lastRootTime < @rootImmunityDuration
    return immune
    
  activateTrap: (thang) ->
    @armed = false
    @rootTimer = @rootDuration
    @triggeredBy = thang
    @rootTarget thang
    @setAction 'attack'
    @setTarget thang
    @act()
    @performAttack thang
    #console.log @world.age, 'activateTrap'
    
  rootTarget: (target) ->
    return unless target
    rootPos = @pos.copy()
    rootPos.z = target.pos.z
    target.pos = rootPos
    target.lastRootTime = @world.age
Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'
Vector = require 'lib/world/vector'

module.exports = class Shields extends Component
  @className: "Reflects"
  isReflecting: false
  
  constructor: (config) ->
    super config
    @reflectRangeSquared = @reflectRange * @reflectRange
    @reflectConvertRangeSquared = @reflectConvertRange * @reflectConvertRange
  
  attach: (thang) ->
    reflectAction = name: 'reflect', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions reflectAction

  reflect: (dir) ->
    # TODO checking
    unless dir.isVector? or not isNaN(dir.x + dir.y)
      throw new ArgumentError "The direction should a vector or an object with x, y and z (optional) properties.", "forcePush", "direction", "object", direction
    
    oldAction = @action
    @setAction 'reflect'
    @reflectDirection = Vector(dir.x, dir.y, dir.z || 0).copy().normalize(true)
    if @act()
      @startReflecting()
      if oldAction is 'reflect'
        @actionActivated = false
    else
      @intent = 'reflect'
    return @block?() unless @commander?

  update: ->
    if @isReflecting
      @reflectProjectiles()
    if @intent is "reflect" and act()
      @startReflecting()
  
  startReflecting: ->
    @intent = undefined
    @rotation = @reflectDirection.heading()
    @keepTrackedProperty "rotation"
    @effects = (e for e in @effects when e.name isnt 'reflect')
    @addEffect {name: 'reflect', duration: @actions['reflect'].cooldown + @world.dt, reverts: true, targetProperty: 'isReflecting', setTo: true, onRevert: => @stopReflecting()}
    @addEffect {name: 'shield', duration: @actions['reflect'].cooldown + @world.dt, setTo: true}
    @brake?() if @isGrounded?()
      
  
  reflectProjectiles: ->
    for thang in @allianceSystem.allAlliedThangs
      if thang.isMissile and thang.collides and not thang.isReflected
        #console.log(thang.collisionCategory)
        ds = @distanceSquared(thang.pos)
        continue if ds > @reflectConvertRangeSquared
        continue if @reflectDirection.copy().dot(thang.pos.copy().subtract @pos) < 0
        if thang.superteam isnt @superteam
          thang.team = @team
          thang.superteam = @superteam
          # Change collision category for them
          thang.body.SetActive false
          thang.collisionCategory = "ground_and_air"
          filterData = thang.body.GetFixtureList().GetFilterData()
          thang.updateCollisionFilterBits filterData, thang.collisionCategory
          thang.body.GetFixtureList().SetFilterData filterData
          thang.body.SetActive true
          thang.updateRegistration()
        
        if ds <= @reflectRangeSquared
          speed = thang.velocity?.magnitude()
        
          thang.isReflected = true
          thang.velocity = @reflectDirection.copy().multiply speed, true
          thang.rotation = thang.velocity.heading()
        #console.log(thang.collisionCategory)
        
    
  stopReflecting: ->
    @reflectDirection = null
    @unblock()
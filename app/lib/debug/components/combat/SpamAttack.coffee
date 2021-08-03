Component = require 'lib/world/component'

module.exports = class SpamAttack extends Component
  @className: 'SpamAttack'
  constructor: (config) ->
    super config
    @spamAngle -= 180
    @disabled ?= false
    @spamEvery ?= 0.2
    @spamNext ?= 0
    @spamFor ?= @spamInterval
    @waitFor ?= @spamCooldown
    @firedMissiles = []
    @VALID_SPEW_DIRECTIONS = ["horizontal", "vertical"]
    @unitTriggerDistanceSquared = @unitTriggerDistance * @unitTriggerDistance

  initialize: ->
    
    Object.defineProperty(@, 'esper_direction', {
      enumerable: true,
      get: () -> @direction,
      set: (x) -> 
        return unless x
        unless x in @VALID_SPEW_DIRECTIONS
          throw new Error "direction property must be set to one of: #{@VALID_SPEW_DIRECTIONS.join(', ')}"
        @direction = x
        @configure_spew_direction x
    })
    Object.defineProperty(@, 'esper_spamInterval', {
      enumerable: true,
      get: () -> @spamInterval,
      set: (x) -> 
        return if x < 0
        @spamFor = x
        @spamInterval = x
    })
    Object.defineProperty(@, 'esper_disabled', {
      enumerable: true,
      get: () -> @disabled,
      set: (x) -> 
        return if typeof(x) is "undefined"
        unless _.isBoolean(x)
          throw new Error "disabled property should be a boolean value"
        return if x == @disabled
        if (x is false) and (@disabled is true)
          @spamFor = @spamInterval
          @waitFor = @spamCooldown
          @spamNext = 0
        @disabled = x
    })

  configure_spew_direction: (dir) ->
    return unless dir in @VALID_SPEW_DIRECTIONS
    if dir is "horizontal"
      @spamAngle = -180
    else if dir is "vertical"
      @spamAngle = -90

  update: ->
    @updateMissiles()
    @spamMissiles() unless @disabled

  spamMissiles: ->
    @spamNext -= @world.dt
    @spamFor -= @world.dt
    @waitFor -= @world.dt unless @spamFor > 0
    
    if @spamFor > 0 
      if @spamNext <= 0
        #console.log "FIRE", @spamFor
        for i in [0...@spamStreams]
          @spawnUnit(Math.cos(deg2Rad @spamAngle + i * 360 / @spamStreams) * 20, Math.sin(deg2Rad @spamAngle + i * 360 / @spamStreams) * 20)
        @spamNext = @spamEvery
      #else
        #console.log "RELOAD", @spamNext
    else if @waitFor <= 0
      @spamFor = @spamInterval
      @waitFor = @spamCooldown
      #console.log "BEGIN SPAM", @spamFor
    #else
      #console.log "COOLDOWN", @waitFor

  spawnUnit: (xVel, yVel) ->
    unit = @instabuild @unitToSpam, @pos.x , @pos.y
    unit.velocity.y = yVel
    unit.velocity.x = xVel
    unit.rotation = unit.velocity.heading()
    unit.maintainsElevation = -> true
    unit.targetsHit = []
    @firedMissiles.push unit
    unit.keepTrackedProperty "rotation"
      
  instabuild: (buildType, x, y, poolName=undefined) ->
    unless @buildXY
      console.error @id, "didn't have buildXY method for use in Referee's instabuild at time", @world.age, "for", buildType, "at", x, y, "with buildTypes", @buildTypes
      return null
    @buildXY buildType, x, y
    thang = @performBuild poolName
    thang.lifespan = 3
    thang
  
  deg2Rad = (degAngle) ->
    return degAngle / (180 / Math.PI)
    

  updateMissiles: ->
    for missile in (@firedMissiles || []) when missile.exists
      if !missile.actions.die?
        missile.addActions name: 'die', cooldown: 1
      for thang in @world.getSystem("Combat").attackables
        if thang isnt @ and not (thang.id in missile.targetsHit) and missile.distanceSquared(thang) < @unitTriggerDistanceSquared and missile.intersects(thang)
          missile.velocity.divide(25)
          thang.takeDamage? 9001, @
          missile.addCurrentEvent 'hit'
          missile.targetsHit.push thang.id
          missile.setAction "die"
          missile.lifespan = 1
          missile.hasCollided = true
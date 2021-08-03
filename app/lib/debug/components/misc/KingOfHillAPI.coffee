Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

VALID_PLAYERS = ['guardian','sorcerer','marksman']
VALID_RECRUITS = ['griffin', 'tiger', 'wolf']

module.exports = class KingOfHillAPI extends Component
  @className: 'KingOfHillAPI'

  # chooseAction: ->
  
  constructor: (config) ->
    super config
    
  attach: (thang) ->
    super thang
    thang.teammates = []
    thang.addTrackedProperties ['teammates', 'array']

  initialize: ->
    return
    
  update: ->
    return unless @proxyHero
    @proxyHero.pos = @pos.copy()
    for prop in @trackedPropertiesKeys
      @proxyHero[prop] = if @[prop]?.copy then @[prop].copy() else @[prop]
    # @proxyHero.hasMoved = true
    # TODO: put all components on the primary hero thang, and then add checks for playAs type to enable/disable
    console.log "POS", @pos, @proxyHero.pos unless _.isEqual(@pos, @proxyHero.pos)
    
  playAs: (type) ->
    if @playingAs
      throw new Error "You can only use playAs once."
    if @world.frames.length > 1
      throw new Error "Use playAs at the start of your code!"
    unless type in VALID_PLAYERS
      throw new Error "You can playAs: " + VALID_PLAYERS.join(', ')
    @playingAs = type
    @configureAbilities()

    @buildXY type, @pos.x, @pos.y
    @proxyHero = @performBuild()
    @proxyHero.cancelCollisions()
    @proxyHero.hidden = true
    @proxyHero.isAttackable = false
    @proxyHero.updateRegistration()
    @proxyHero.keepTrackedProperty 'pos'
    
    
    @proxyHero.trackedPropertiesKeys = @trackedPropertiesKeys
    @proxyHero.trackedPropertiesTypes = @trackedPropertiesTypes
    @proxyHero.trackedPropertiesUsed = _.clone @trackedPropertiesUsed
    @trackPropertiesUsed = (false for prop in @trackedPropertiesUsed)
    
    # Any properties tracked on the hero should be tracked on the proxy instead.
    @keepTrackedProperty = (prop) =>
      propIndex = @proxyHero.trackedPropertiesKeys.indexOf prop
      if propIndex isnt -1
        @proxyHero.trackedPropertiesUsed[propIndex] = true
        # @trackedPropertiesUsed[propIndex] = true
        
    @type = type
    if type is 'guardian'
      @maxHealth = 6000
      @health = @maxHealth
      @attackDamage = 100
      @attackRange = 4
      @maxSpeed = 7
      
    if type is 'sorcerer'
      @maxHealth = 3000
      @health = @maxHealth
      @attackDamage = 40
      @attackRange = 25
      @maxSpeed = 14
      
    if type is 'marksman'
      @maxHealth = 4000
      @health = @maxHealth
      @attackDamage = 80
      @attackRange = 30
      @maxSpeed = 10
    

    
  configureAbilities: ->
    
    if @playingAs isnt 'sorcerer'
    
      @manaBlast = -> throw new Error("Only the 'sorcerer' hero can use the `manaBlast` ability")
      @cast = -> throw new Error("Only the 'sorcerer' hero can `cast` spells")
      @['perform_summon-burl'] = -> throw new Error("Only the 'sorcerer' hero can `cast` spells")
      #force-bolt H
      #summon-burl? H
      #swap H

    if @playingAs isnt 'marksman'
    
      @hide = -> throw new Error("Only the 'marksman' hero can use the `hide` ability")
      @envenom = -> throw new Error("Only the 'marksman' hero can use the `envenom` ability")
      @blink = -> throw new Error("Only the 'marksman' hero can use the `blink` ability")
      @charm = -> throw new Error("Only the 'marksman' hero can use the `charm` ability")

    if @playingAs isnt 'guardian'
    
      @shield = -> throw new Error("Only the 'guardian' hero can use the `shield` ability")
      @slam = -> throw new Error("Only the 'guardian' hero can use the `slam` ability")
      @terrify = -> throw new Error("Only the 'guardian' hero can use the `terrify` ability")
      @bash = -> throw new Error("Only the 'guardian' hero can use the `bash` ability")
    
    
  recruit: (type) ->
    if type not in VALID_RECRUITS
      throw new Error "You can recruit: " + VALID_RECRUITS.join(', ')
    if @teammates.length >= 2
      throw new Error "You can only recruit 2 teammates."
    if type in @teammates
      throw new Error "You can't recruit #{type} twice!"
    @buildXY type, @pos.x + @direction * 2, @pos.y
    thang = @performBuild()
    @teammates.push type
    @keepTrackedProperty 'teammates'
    thang.direction = @direction
    thang.isHittable = true
    thang.moveTo = @moveTo
    thang.moveToXY = @moveToXY
    thang.hit = @hit
    thang.moveToward = @moveToward
    thang.moveTowardPos = @moveTowardPos
    thang.lastHit = 0
    thang.hitCooldown = @hitCooldown
    thang

  
  random: (min, max) ->
    @world.rand.randf2 min, max

Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

module.exports = class CatchesArrows extends Component
  @className: 'CatchesArrows'
  
  constructor: (config) ->
    super config
    @catchRadiusSquared = @catchRadius * @catchRadius
  
  attach: (thang) ->
    catchAction = {name: "catch", cooldown: @cooldown, specificCooldown: @specificCooldown}
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions catchAction
  
  catch: (missile) ->
    #console.log("TRY", missile)
    unless missile?
      throw new ArgumentError "Target is null. Is there always a target to bash? (Use if?)", "bash", "target", "object", target
    @setTarget missile
    #console.log("SET")
    unless missile.isMissile and missile.diesOnHit?
      @say? "Can't catch it"
      return
    @intent = "catch"
    @block?()
  
  update: () ->
    return unless @intent is "catch"
    unless @target and @target.exists and not @target.collidedWith?
      @target = null
      @intent = null
      @setAction "idle"
      @unblock?()
      return
    if @distanceSquared(@target) > @catchRadiusSquared
      @setAction "move"
    else
      @setAction "catch"
    if @action is "catch" and @act()
      @performCatch()
  
  performCatch: () ->
    @unblock?()
    if @target
      @target.diesOnHit = true
      @target.beginContact? @
      @sayWithoutBlocking @catchPhrase if @catchPhrase isnt ""
    @intent = null
    @target = null
    
  
  chooseAction: ->
    return if @hasBeenCommanded or not @catchPassive
    return unless @isReady("catch")
    arrows = (a for a in @getEnemyMissiles() when a.diesOnHit? and not a.collidedWith? and  @distanceSquared(a) <= @catchRadiusSquared)
    nearestArrow = @findNearest arrows
    if nearestArrow
      @setAction "catch"
      @setTarget nearestArrow
      @act()
      @performCatch()
    
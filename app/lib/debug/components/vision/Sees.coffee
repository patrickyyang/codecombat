Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Sees extends Component
  @className: 'Sees'
  constructor: (config) ->
    super config
    @visualRangeSquared = @visualRange * @visualRange
    
  attach: (thang) ->
    super thang
    thang.aiSystem = thang.world.getSystem('AI')
    thang.visionSystem = thang.world.getSystem('Vision')
    thang.alwaysIgnoresLineOfSight = thang.visionSystem?.checksLineOfSight is false

  canSee: (thang, ignoreLineOfSight=false) ->
    #console.log @id, 'testing canSee on', thang.id, 'at d2', @distanceSquared(thang), 'with v2', @visualRangeSquared, 'v', @visualRange, 'aalos', @alwaysIgnoresLineOfSight, 'stw', @seesThroughWalls if @id is 'Hero Placeholder 1'
    return false if thang.hidden
    return true if @visualRange > 9000 and @alwaysIgnoresLineOfSight
    return false if @distanceSquared(thang) >= @visualRangeSquared
    return true if @seesThroughWalls or ignoreLineOfSight
    return false if @aiSystem and not @aiSystem.isPathClear(@pos, thang.pos, thang, true)
    true

  getVisibleThangs: ->
    _.filter @world.thangs, @canSee

  getByType: (type, thangs) ->
    if thangs
      _.filter thangs, (thang) => thang.type is type and thang.exists
    else
      _.filter @world.thangs, (thang) => thang.type is type and thang.exists and thang isnt @ and not thang.dead and (@canSee(thang) or (thang.superteam is @superteam and @superteam and not thang.hidden))
    
  findByType: (type, thangs) ->
    unless _.isString type
      throw new ArgumentError "", "findByType", "type", "string", type
    if thangs and not _.isArray thangs
      throw new ArgumentError "Pass an optional array of units as second parameter", "findByType", "units", "thangs", thangs
    @getByType type, thangs

  findNearestByType: (type, thangs) ->
    @getNearest @findByType(type, thangs)

  getFlags: ->
    (flag for flag in @visionSystem.flags when flag.exists and flag.team is @team)

  findFlags: ->
    @getFlags()

  findFlag: (color) ->
    if color and not (color in ["green", "black", "violet"])
      throw new ArgumentError 'Pass a flag color to find: "green", "black", or "violet".', "findFlag", "color", "string", color
    for flag in @findFlags()
      return flag if flag.color is color or not color
    null

  removeFlag: (flag) ->
    if _.isString flag
      throw new ArgumentError "Remove a flag object instead of a color string.", "removeFlag", "flag", "flag", flag
    unless flag and flag.team and flag.color
      throw new ArgumentError "Pass a flag object to remove.", "removeFlag", "flag", "flag", flag
    unless flag.team is @team
      throw new ArgumentError "#{@id} (team #{@team}) can't remove #{flag.id} (team #{flag.team}).", "removeFlag", "flag", "flag", flag
    flagEvent = team: @team, color: flag.color, time: @world.age, active: false, player: "Code (#{@team})", source: 'code'
    @world.addFlagEvent flagEvent
    @visionSystem.processFlagEvent flagEvent

  update: ->
    return unless @intent is 'pickUpFlag'
    if not @flagTarget?
      @intent = undefined
      return @unblock?()
    if @flagTarget? and @flagTarget.pos.x isnt @targetPos.x or @flagTarget.pos.y isnt @targetPos.y
      @setTargetPos @flagTarget.pos
    if @distanceSquared(@flagTarget.pos) <= @flagPickupRange * @flagPickupRange
      if @flagTarget?
        @removeFlag @flagTarget
      @intent = undefined
      @flagTarget = null
      @brake?()
      @unblock?()

  pickUpFlag: (flag) ->
    if _.isString flag
      throw new ArgumentError "Pick up a flag object instead of a color string.", "pickUpFlag", "flag", "flag", flag
    unless flag and flag.team and flag.color
      throw new ArgumentError "Pass a flag object to pick up.", "pickUpFlag", "flag", "flag", flag
    unless flag.team is @team
      throw new ArgumentError "#{@id} (team #{@team}) can't pick up #{flag.id} (team #{flag.team}).", "pickUpFlag", "flag", "flag", flag
    unless @move?
      throw new ArgumentError "#{@id} can't move, so can't pick up #{flag.id}.", "pickUpFlag", "flag", "flag", flag
    flag = @world.getThangByID flag.id  # Fix for Python object mangling
    return unless flag.exists
    # TODO: Make this happen inside the update, or something, probably not a big issue though
    @flagPickupRange = 1.5
    if @built
      for thang in @built
        if thang.collisionCategory is 'obstacles' and thang.intersects flag
          # Hack: we couldn't pick up a flag we built a fence wall over otherwise.
          @flagPickupRange = 4
          break
    @setTargetPos flag.pos, "pickUpFlag"
    if @distanceSquared(@targetPos) <= @flagPickupRange * @flagPickupRange
      @intent = "pickUpFlag"
      @removeFlag flag
      @flagTarget = null
      @setAction 'idle'
      @setTarget null
      @brake?()
      return @block?()
    else
      @flagTarget = flag
      @intent = "pickUpFlag"
      @setAction 'move'
      return @block?()

  addFlag: (color, targetPos) ->
    unless color in ['green', 'black', 'violet']
      throw new ArgumentError "Pass a flag color to create.", "addFlag", "color", "string", color
    unless targetPos and _.isNumber(targetPos.x) and _.isNumber(targetPos.y)
      throw new ArgumentError "Pass a flag position to create.", "addFlag", "targetPos", "object", targetPos
    team = @team ? 'humans'
    targetPos = x: targetPos.x, y: targetPos.y
    flagEvent = player: "Code (#{team})", team: team, color: color, time: @world.age, active: true, pos: targetPos, source: 'code'
    @world.addFlagEvent flagEvent
    @visionSystem.processFlagEvent flagEvent

  findHazards: ->
    @collisionSystem ?= @world.getSystem "Collision"
    (t for t in @collisionSystem.extantColliders when t.isHazard and not t.dead)

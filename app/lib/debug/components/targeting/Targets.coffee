Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'
Vector = require 'lib/world/vector'

module.exports = class Targets extends Component
  @className: 'Targets'
  target: null
  targetPos: null
  attach: (thang) ->
    super thang
    thang._allTargets ?= []  # We keep track internally and add the trackedFinalProperty value at the end for performance
    thang.addTrackedProperties ["targetPos", "Vector"]
    thang.addTrackedProperties ["target", "Thang"]
    thang.addTrackedFinalProperties "allTargets"

  setTarget: (target, methodName='setTarget') ->
    oldTargetPos = @getTargetPos()
    @targetPos = null
    if target and not target.isThang and _.isString(target.id) and targetThang = @world.getThangByID target.id
      # Temporary workaround for Python API protection bug that makes them not Thangs
      target = targetThang
    if not target?
      target = null
    else if (target.isVector) or (_.isPlainObject(target) and (target.x? or target.y?))
      throw new ArgumentError "Target a unit, not an {x, y} position.", methodName, "target", "unit", target
    else if target and _.isString target
      targetThang = @world.getThangByID target
      if not targetThang
        targetThang = @world.getThangByID _.string.titleize target
        if targetThang
          throw new ArgumentError "Attack \"#{_.string.titleize(target)}\", not \"#{target}\". (Capital letters are important.)", methodName, "target", "unit", target
      unless targetThang
        if /^enemy\d*$/.test target
          throw new ArgumentError "Target an enemy variable, not the string \"#{target}\". (Try using findNearestEnemy.)", methodName, "target", "unit", target
        if target is "target"
          throw new ArgumentError 'Target an enemy by name, like `"Treg"`, not the string `"target"`.', methodName, "target", "unit", target
        if target is "Enemy Name"
          throw new ArgumentError 'Target an enemy by name, like `"Treg"`, not the string `"Enemy Name"`.', methodName, "target", "unit", target
        if target in ["ogre", "ogres", "munchkin"]
          throw new ArgumentError "Target a particular ogre, not the string \"#{target}\". (Try using its name or findNearestEnemy.)", methodName, "target", "unit", target
        [closestMatch, closestScore, message] = [null, 0, '']
        for enemy in @getEnemies?() ? []
          matchScore = enemy.id.score target, 0.8
          [closestMatch, closestScore, message] = [enemy, matchScore, "Attack \"#{enemy.id}\", not \"#{target}\"."] if matchScore > closestScore
        if closestScore >= 0.5
          throw new ArgumentError message, methodName, "target", "unit", target
        throw new ArgumentError "There's no one named \"#{target}\" to target.", methodName, "target", "unit", target
      target = targetThang
    else unless target.isThang
      throw new ArgumentError "Target a unit.", methodName, "target", "unit", target
    if target?.hidden
      target = null
    @target = target
    if @target
      @trackTargetPos @target.pos, oldTargetPos
      @keepTrackedProperty 'target'

  setTargetPos: (pos, methodName='setTargetPos') ->
    oldTargetPos = @getTargetPos()
    @target = null
    if not pos?
      @targetPos = null
    else if pos.isVector
      @targetPos = pos.copy()
    else if _.isPlainObject(pos) and (pos.x? or pos.y?)
      @targetPos = new Vector pos.x, pos.y, pos.z
    else
      throw new ArgumentError "Target an {x: number, y: number} position.", methodName, "pos", "object", pos
    if @targetPos
      for k in ["x", "y", "z"]
        unless (_.isNumber(@targetPos[k]) and not _.isNaN(@targetPos[k]) and @targetPos[k] isnt Infinity) or (k is "z" and not @targetPos[k]?)
          targetPos = @targetPos
          @targetPos = null
          throw new ArgumentError "Target an {x: number, y: number} position.", methodName, "pos.#{k}", "number", targetPos[k]
    if @targetPos
      @trackTargetPos @targetPos, oldTargetPos
      @keepTrackedProperty 'targetPos'

  setTargetXY: (x, y, z, methodName='setTargetXY') ->
    for k in [["x", x], ["y", y], ["z", z]]
      unless (_.isNumber(k[1]) and not _.isNaN(k[1]) and k[1] isnt Infinity) or (k[0] is "z" and not k[1]?)
        throw new ArgumentError "Target an {x: number, y: number} position.", methodName, k[0], "number", k[1]
    @setTargetPos new Vector(x, y, z), methodName

  trackTargetPos: (targetPos, oldTargetPos) ->
    return if targetPos.equals oldTargetPos
    closeEnough = false
    for i in (x for x in [0 .. @_allTargets.length] by 2)
      if Math.abs(@_allTargets[i] - targetPos.x) < 1 and Math.abs(@_allTargets[i + 1] - targetPos.y) < 1
        closeEnough = true
        break
    unless closeEnough
      @_allTargets.push targetPos.x, targetPos.y

  getTargetPos: ->
    @targetPos ? @target?.pos
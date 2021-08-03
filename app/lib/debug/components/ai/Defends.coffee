Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Defends extends Component
  @className: "Defends"
  
  attach: (thang) ->
    super thang
    if _.isString thang.defendTarget
      thang.defendTarget = thang.world.getThangByID thang.defendTarget
  
  chooseAction: ->
    return unless @defendTarget or @defendTargetPos
    return @defendTarget = null if @defendTarget?.dead
    @choosingDefendAction = true
    nearestEnemy = @getNearestEnemy()
    targetPos = @defendTarget?.pos ? @defendTargetPos
    targetPos = Vector.add targetPos, @defendPosOffset if @defendPosOffset and @defendTargetPos
    nearestEnemy = null if nearestEnemy and targetPos and nearestEnemy.distance(targetPos, true) > @attackRange + 3
    if nearestEnemy
      @chaseAndAttack nearestEnemy
    else if targetPos and @distance(targetPos) > 3
      if @defendTarget
        @follow @defendTarget
      else
        @move targetPos
    else
      @setAction 'idle'
      @setTarget null
    @choosingDefendAction = false

  defend: (target) ->
    return @defendPos @pos unless target and target.isThang
    @defendTarget = target
    @defendTargetPos = null
    
  defendPos: (targetPos) ->
    targetPos ?= @pos
    for k in ["x", "y", "z"]
      unless (_.isNumber(targetPos[k]) and not _.isNaN(targetPos[k]) and targetPos[k] isnt Infinity) or (k is "z" and not targetPos[k]?)
        throw new ArgumentError "Target an {x: number, y: number} position.", "defendPos", "pos.#{k}", "number", targetPos[k]
    @defendTargetPos = new Vector targetPos.x, targetPos.y
    @defendTarget = null

  stopDefending: ->
    @defendTarget = @defendTargetPos = null

  setAction: (action) ->
    # If we set action from somewhere else, we assume that we've stopped defending.
    @stopDefending() unless @choosingDefendAction

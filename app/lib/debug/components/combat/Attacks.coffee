Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

allTimeDefenderCount = 0

module.exports = class Attacks extends Component
  @className: 'Attacks'
  constructor: (config) ->
    super config
    @_attackAction = name: 'attack', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    @usesRangedAttack = @attackRange >= 10

  attach: (thang) ->
    @attackDamage *= thang.attackDamageFactor or 1
    super thang
    thang.addActions @_attackAction if thang.acts

  canAttack: ->
    return false unless @canAct()
    return false unless @target?.isAttackable or @targetPos
    return true if @attacksWhenOutOfRange
    distance = @distance (@target ? @targetPos), not @usesRangedAttack
    return true if distance - 0.5 <= @attackRange
    unless @attackedWhenOutOfRange
      @publishNote 'thang-attacked-when-out-of-range', {}
      @attackedWhenOutOfRange = true
    if @complainsWhenAttackingOutOfRange
      @sayWithoutBlocking "#{@target or @targetPos} out of range\n(distance #{distance.toFixed(0)} / range #{@attackRange.toFixed(0)})"
    false
    
  getAttackMomentum: (targetPos) ->
    return null unless @attackMass
    dir = targetPos.copy().subtract(@pos).normalize()
    dir.z = if @attackZAngle then Math.sin @attackZAngle else 0
    dir.normalize().multiply @attackMass, true

  performAttack: (target, damageRatio=1, momentum=null) ->
    momentum ?= @getAttackMomentum target.pos ? target
    attacker = if @attackerReplacement? then @attackerReplacement  else @
    target.takeDamage? @attackDamage * damageRatio, attacker, momentum
    #console.log @world.frames.length, @id, "attacked ", target.id, "for", @attackDamage * damageRatio, 'damage; hp', target.health, 'momentum', momentum, 'from attackMass', @attackMass, 'attackZAngle', @attackZAngle
    @brake?() unless @missileSpriteName or @health <= 0

  clearAttack: ->
    @setAction 'idle' # double setAction warning in chooseAction levels
    @setTarget null
    @intent = undefined
  
  finishUnblocking: ->
    return unless @intent is 'attack'
    @intent = undefined
    target = @target
    finishedAttacking = @plan and (@targetPos? or @target?.health <= 0)  # already attacked pos, or both had "health" and now is dead
    if finishedAttacking
      @clearAttack()
    if target?.health <= 0
      @returnToNearestSnapPoint?()

  updateAttack: ->
    # TODO: Check if the enemy's health is equal or under 0 and clear the attack early if so
    unless @target or @targetPos
      @setAction 'idle'
      @setTarget null
      @unblock?()
      @singleFrameAttack = false
      return false
    # Returns whether or not we are blocking
    if @singleFrameAttack  # Because of attackMovesIncrementally
      @unblock?()
      @singleFrameAttack = false
      return false
    # We may be able to get rid of @chasesWhenAttackingOutOfRange
    if @actions.move and @chasesWhenAttackingOutOfRange and @distance(@target ? @targetPos, not @usesRangedAttack) > @attackRange and (not @target?.dead or @announceAction)
      @currentSpeedRatio = 1
      @setAction 'move'
      return true
    else if @plan and @target?.health <= 0 and @target.id not in ['Door', 'Chest', 'Cupboard']
      @clearSpeech?()
      @sayWithoutBlocking? "... but it's dead!"
      if @attackMovesIncrementally
        @singleFrameAttack = false
      else
        @clearAttack()
      @unblock?()
      return false
    else
      @setAction 'attack'
      return true

  attack: (target) ->
    if typeof target is 'undefined' or (not target? and @hasEnemies())
      # If there are no enemies left, don't sweat it--they've killed everyone anyway.
      if @inventoryIDs and  @inventoryIDs["programming-book"] == "Programmaticon I"
        throw new ArgumentError "Is there an enemy within your line-of-sight yet?", "attack", "enemy"
      else
        throw new ArgumentError "Target is null. Is there always a target to attack? (Use if?)", "attack", "target", "object", target
    unless target
      if _.isString target and _.isEmpty target
        throw new ArgumentError 'Target an enemy by name, like "Treg".', "attack", "target", "unit", target
      return
    @setTarget target, 'attack'
    @hasAttacked = true  # if startsPeaceful then we're no longer peaceful
    @announceAction? 'attack'
    @specificAttackTarget = @target if @commander
    @intent = "attack"
    
    shouldBlock = @updateAttack()
    if @attackMovesIncrementally  # Useful for slow heroes chasing targets (i.e. Ace of Coders' Okar)
      @singleFrameAttack = true
      return @block?()
    if shouldBlock
      return @block?() unless @commander
    else
      @returnToNearestSnapPoint?()
      return null

  attackPos: (targetPos) ->
    if typeof targetPos is 'undefined'
      throw new ArgumentError "You need a position to attack.", 'attackPos', "targetPos", "object", targetPos
    @setTargetPos targetPos, "attackPos"
    @intent = "attack"
    @targetPos.z = 0  # Don't allow unlimited z range for missiles
    if @actions.move and @chasesWhenAttackingOutOfRange and @distance(targetPos, not @usesRangedAttack) > @attackRange
      # Don't use with plan()
      @currentSpeedRatio = 1
      @setAction 'move'
      #return @setAction 'move'
    else
      @setAction 'attack'
    return @block?()

  attackXY: (x, y, z) ->
    for k in [["x", x], ["y", y], ["z", z]]
      unless (_.isNumber(k[1]) and not _.isNaN(k[1]) and k[1] isnt Infinity) or (k[0] is "z" and not k[1]?)
        throw new ArgumentError "Attack an {x: number, y: number} position.", "attackXY", k[0], "number", k[1]
    @attackPos new Vector x, y, z

  attackNearestEnemy: ->
    if arguments[0]?
      throw new ArgumentError '', "attackNearestEnemy", "", "", arguments[0]
    lastAttackTarget = if @target?.health? then @target else null
    killed = lastAttackTarget?.health < 0
    if killed
      @setTarget null
      return "done"
    enemy = @getNearestEnemy()
    if enemy
      distance = @distance enemy, not @usesRangedAttack
      if @actions.move and distance > @attackRange
        @follow enemy
      else
        @attack enemy
    else
      @setTarget null
    @action

  chaseAndAttack: (target) ->
    return unless target.isAttackable
    if @distance(target, not @usesRangedAttack) <= @attackRange
      @attack target
    else
      @currentSpeedRatio = 1
      @follow target

  update: ->
    @updateDefend() if @intent is 'defend'
    
  updateDefend: ->
    # Old defend method moved into the update function
    
    unless @defenderOffsetPriority?
      @defenderOffsetPriority = allTimeDefenderCount++  # Semi-consistent priority for defend offsets
      @defenderOffsetPriority += @attackRange * 1000000  # Long-ranged defenders will go in the back
      @defenderOffsetPriority -= @maxHealth * 1000  # High-health defenders will go in the front
    offsetMagnitude = @width / 2
    # Get the position of our target as a Vector
    if @defendPriorityTarget.isVector
      pos = @defendPriorityTarget
    else if @defendPriorityTarget.isThang
      pos = @defendPriorityTarget.pos.copy()
      # larger offset when defending a thang, to allow for personal space
      offsetMagnitude = Math.max(offsetMagnitude, (@width / 2) + (@defendPriorityTarget.width / 2))
      enemy = @defendPriorityTarget.getNearestEnemy()
    else unless _.isNaN @defendPriorityTarget.x + @defendPriorityTarget.y
      pos = new Vector @defendPriorityTarget.x, @defendPriorityTarget.y
    else
      throw new ArgumentError 'Must defend a target or an {x,y} position', 'defend'
      
    @defendTarget = @defendPriorityTarget if @commander  # Remember the last command in case commands cease
    
    # Guard is the distance we want to keep with the target if there are enemies
    if @attackRange < 10
      guardMagnitude = Math.max offsetMagnitude, (@maxSpeed / 2)
    else
      guardMagnitude = Math.max offsetMagnitude, 5 - @attackRange / 10
    
    distToTarget = @distance(pos, true)

    # Leeway is so we can move farther than <guard> from the target to get into attack range.
    # had problems where defenders would sit there and not attack
    leeway = @attackRange
    leeway += 1 unless @attackRange > 10

    # If target is a thang, use it's nearest enemy (set above). If not, use our nearest enemy
    enemy ?= @getNearestEnemy()
    
    if enemy
      enemyToTarget = enemy.distance(pos, true)
      distToEnemy = @distance(enemy, true)
      # if they can attack farther than we can, we need to be able to get closer?
      leeway = Math.max(leeway, (enemy.attackRange + 1))
    # Get close to target if there is no enemy
    if not enemy and distToTarget > offsetMagnitude and @move
      @setTargetPos pos
      @setAction 'move'
    # If the we are far from the target, keep getting closer even if there's an enemy
    else if enemy and (distToTarget > guardMagnitude + leeway) and @move
      @setTargetPos pos
      @setAction 'move'
    # If the enemy is far from the target, move to intercept position, but not too far from target
    else if enemy and (enemyToTarget > guardMagnitude + leeway) and @move
      intercept = enemy.pos.copy().subtract(pos).normalize().multiply(guardMagnitude)
      @adjustDefendInterceptForFormation intercept if @defendTarget
      @setTargetPos pos.copy().add(intercept)
      if @targetPos.distance(enemy.pos) - @width / 2 - enemy.width / 2 <= @attackRange
        @attack(enemy)
      else
        @setAction 'move'
    # If enemy is close enough to target, move in and attack.
    else if enemy and (enemyToTarget <= guardMagnitude + leeway)
      # Use attack to do our logic, but ensure we are still defending our target
      @attack enemy
      @intent = 'defend'
    # If there's not an enemy close enough to the pos, but we can still shoot one in range to us, do it (arrow towers).
    else if enemy and @distance(enemy) < @attackRange
      # Use attack to do our logic, but ensure we are still defending our target
      @attack enemy
      @intent = 'defend'
    else
      @brake?()
      @setAction 'idle'

    
  defend: (target) ->
    @intent = "defend"
    @defendPriorityTarget = target
    if not target
      throw new ArgumentError 'Must defend a target or an {x,y} position', 'defend'
    @updateDefend()

  adjustDefendInterceptForFormation: (intercept) ->
    alliedDefenders = _.filter(@getFriends(), (f) =>
      f.defendTarget and
      ((f.defendTarget.id and f.defendTarget.id is @defendTarget.id) or
       (f.defendTarget.x is @defendTarget.x and f.defendTarget.y is @defendTarget.y))
      ).concat(@)
    alliedDefenders = _.sortBy alliedDefenders, 'defenderOffsetPriority'
    thisDefenderIndex = alliedDefenders.indexOf @
    angle = thisDefenderIndex / alliedDefenders.length * Math.PI
    if thisDefenderIndex % 2
      angle *= -1  # Flip to the right side for every other
    intercept.rotate angle
    if alliedDefenders.length > 6
      intercept.multiply 1 + alliedDefenders.length / 6 / Math.PI
    #console.log @world.age, @id, 'got intercept', intercept, 'from angle', angle, 'for defender index', thisDefenderIndex, 'of', alliedDefenders.length, 'with priority', @defenderOffsetPriority
    intercept

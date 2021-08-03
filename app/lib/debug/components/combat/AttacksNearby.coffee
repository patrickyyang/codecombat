Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

module.exports = class AttacksNearby extends Component
  @className: "AttacksNearby"
  constructor: (config) ->
    super config
    @attackNearbyEnemyRange ?= @attackRange * 3

  # Alias for use in Taunt the Guards, since I can't figure out how to get aliasing working
  # otherwise in a plan()-based programming environment.
  bustDownDoor: (args...) ->
    return @attackNearbyEnemy args...
    
  attackNearbyEnemy: ->
    if arguments[0]?
      throw new ArgumentError "", "attackNearby", "", "", arguments[0]
    # Kill the nearest enemy, or wait a little bit and then give up if it's too far
    @attackingNearbyEnemySince ?= @world.age
    lastAttackTarget = if @target?.health? then @target else null
    killed = lastAttackTarget?.health <= 0
    #console.log "Did we kill it?", lastAttackTarget?.id, @target?.id, @target?.isAttackable, killed
    if killed
      @setTarget null
      return "done"

    frustratedMessage = "No nearby enemies..."
    enemy = @getNearestEnemy()
    distance = if enemy then @distance(enemy) else 9001
    canMove = distance < @attackNearbyEnemyRange
    if canMove
      if @currentlySaying?.message is frustratedMessage
        @say null
      @attackingNearbyEnemySince = @world.age
      if @canAttack()
        @attack enemy
      else
        @follow enemy
      return @action

    idleTime = @world.age - @attackingNearbyEnemySince
    if idleTime > 3 + @attackNearbyEnemyWaitTime
      return "done"
    else if Math.abs(idleTime - @attackNearbyEnemyWaitTime) <= @world.dt
      @say frustratedMessage

    @action

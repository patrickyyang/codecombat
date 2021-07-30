System = require 'lib/world/system'
Vector = require 'lib/world/vector'
{MAX_COOLDOWN} = require 'lib/world/systems/action'

module.exports = class Combat extends System
  constructor: (world, config) ->
    super world, config
    @attackers = @addRegistry (thang) -> thang.attack and thang.exists
    @attackables = @addRegistry (thang) -> thang.isAttackable and thang.exists
    @corpses = @addRegistry (thang) -> thang.dead and thang.exists
    @throwers = @addRegistry (thang) -> thang.throw and thang.exists
    @teamDamage = {}

  update: ->
    # To optimize
    hash = 0
    for thang in @attackers
      continue if thang.dead
      continue unless ((thang.action is 'attack' or thang.intent is 'attack') or (thang.action is 'attack' and thang.intent is 'defend')) and targetPos = thang.getTargetPos()
      thang.rotation = Vector.subtract(targetPos, thang.pos).heading()  # Face target
      thang.hasRotated = true
      if thang.action is 'attack' and thang.canAttack() and thang.act()
        thang.performAttack thang.target ? thang.targetPos
        thang.unblock?()
        hash += @hashString(thang.id) * thang.rotation * @world.age
      else if thang.canAct()
        thang.updateAttack()

    for thang in @attackables.slice()  # @attackables might be modified during iteration
      if thang.health <= 0 and not thang.dead
        thang.die()
      hash += @hashString(thang.id) * thang.health * @world.age
      
    for thang in @throwers
      continue unless (thang.action is 'throw' or thang.intent is 'throw') and targetPos = thang.getTargetPos()
      if thang.distance(targetPos) - 0.5 <= thang.throwRange
        thang.setAction 'throw'
      else if thang.actions.move
        thang.setAction 'move'
      if thang.action is 'throw' and thang.canThrow() and thang.act()
        thang.performThrow thang.target
        hash += @hashString(thang.id) * thang.rotation * @world.age
    hash

  damageDealtForTeam: (team) ->
    @teamDamage[team]?.dealt ? 0
    
  damageTakenForTeam: (team) ->
    @teamDamage[team]?.taken ? 0

  defeatedByTeam: (team) ->
    @teamDamage[team]?.defeated ? 0

  defeatedOnTeam: (team) ->
    @teamDamage[team]?.defeatedOn ? 0

  addDamage: (fromTeam, toTeam, damage) ->
    if fromTeam
      @teamDamage[fromTeam] ?= dealt: 0, taken: 0, defeated: 0, defeatedOn: 0
      @teamDamage[fromTeam].dealt += damage if fromTeam isnt toTeam
    if toTeam
      @teamDamage[toTeam] ?= dealt: 0, taken: 0, defeated: 0, defeatedOn: 0
      @teamDamage[toTeam].taken += damage
    #console.log 'adding damage', damage, 'from', fromTeam, 'to', toTeam, 'and have', @teamDamage[fromTeam].dealt, 'dealt,', @teamDamage[toTeam].taken, 'taken'

  addDefeated: (byTeam, onTeam) ->
    if byTeam
      @teamDamage[byTeam] ?= dealt: 0, taken: 0, defeated: 0, defeatedOn: 0
      @teamDamage[byTeam].defeated++ if byTeam isnt onTeam
    if onTeam
      @teamDamage[onTeam] ?= dealt: 0, taken: 0, defeated: 0, defeatedOn: 0
      @teamDamage[onTeam].defeatedOn++
    #console.log 'adding defeated by', byTeam, 'on', onTeam, 'and have', @teamDamage[byTeam]?.defeated, 'defeated,', @teamDamage[onTeam]?.defeatedOn, 'defeatedOn'
    
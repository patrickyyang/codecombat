Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

# The find- methods are player-facing and do argument validation. The get- methods are internal.
# We decided find- was a better prefix, but kept the get- methods since that's how we started doing it.

module.exports = class Allied extends Component
  @className: 'Allied'
  significantProperty: 'isAttackable'
  constructor: (config) ->
    super config
    @superteam ||= @team

  attach: (thang) ->
    super thang
    thang.allianceSystem = thang.world.getSystem("Alliance")

  getFriends: ->
    # Optimize
    return [] unless @canSee
    friends = []
    for thang in @allAllies
      # t.isAttackable is to exclude missiles; seems to work pretty well so far.
      if thang isnt @ and thang[@significantProperty] and not thang.hidden
        friends.push thang
    friends
    
  findFriends: ->
    if arguments[0]?
      throw new ArgumentError '', "findFriends", "", "", arguments[0]
    @getFriends()

  hasFriends: ->
    for thang in @allAllies
      if thang isnt @ and thang[@significantProperty] and @canSee thang, true  # Ignoring LOS for now
        return true
    false

  getCombatants: ->
    return [] unless @canSee
    combatants = []
    for thang in @allianceSystem.allAlliedThangs
      if thang[@significantProperty] and @canSee(thang) and thang isnt @
        combatants.push thang
    combatants
    
  findCombatants: ->
    if arguments[0]?
      throw new ArgumentError '', "findCombatants", "", "", arguments[0]
    @getCombatants()
    
  findCorpses: ->
    if arguments[0]?
      throw new ArgumentError '', "findCorpses", "", "", arguments[0]
    corpses = _.filter @world.getSystem('Combat').corpses, (corpse) -> corpse.hasEffects
    corpses

  getEnemies: ->
    # Optimize
    return [] unless @canSee
    enemies = []
    for thang in @allianceSystem.allAlliedThangs
      if thang.superteam isnt @superteam and thang[@significantProperty] and @canSee thang
        enemies.push thang
    enemies
    
  findEnemies: ->
    if arguments[0]?
      throw new ArgumentError '', "findEnemies", "", "", arguments[0]
    @getEnemies()

  hasEnemies: ->
    for thang in @allianceSystem.allAlliedThangs
      if thang.superteam isnt @superteam and thang[@significantProperty]
        return true
    false

  getEnemyMissiles: ->
    # Optimize
    return [] unless @canSee
    enemyMissiles = []
    for thang in @allianceSystem.allAlliedThangs
      if thang.isMissile and thang.superteam isnt @superteam and @canSee thang
        enemyMissiles.push thang
    enemyMissiles
    
  findEnemyMissiles: ->
    if arguments[0]?
      throw new ArgumentError '', "findEnemyMissiles", "", "", arguments[0]
    @getEnemyMissiles()
    
   getFriendlyMissiles: ->
    # Optimize
    return [] unless @canSee
    friendlyMissiles = []
    for thang in @allianceSystem.allAlliedThangs
      if thang.isMissile and thang.superteam is @superteam and @canSee thang
        friendlyMissiles.push thang
    friendlyMissiles
    
  findFriendlyMissiles: ->
    if arguments[0]?
      throw new ArgumentError '', "findFriendlyMissiles", "", "", arguments[0]
    @getFriendlyMissiles()    

  getNearestFriend: ->
    @getNearest @getFriends()
    
  findNearestFriend: ->
    if arguments[0]?
      throw new ArgumentError "", "findNearestFriend", "", "", arguments[0]
    @getNearestFriend()

  getNearestEnemy: ->
    @getNearest @getEnemies()
    
  findNearestEnemy: ->
    if arguments[0]?
      throw new ArgumentError "", "findNearestEnemy", "", "", arguments[0]
    enemy = @getNearestEnemy()
    if @announceAction
      if enemy
        @announceAction "findNearestEnemy: I see you.", true
      else
        @announceAction "findNearestEnemy: I don't see anyone.", true
    enemy
    
  getNearestEnemyValidateReturn: (ret) ->
    if ret? and not ret instanceof Thang
      throw new ArgumentError "", "getNearestEnemy", "return", "Thang", ret

  getNearestCombatant: ->
    @getNearest @getCombatants()
    
  findNearestCombatant: ->
    if arguments[0]?
      throw new ArgumentError "", "findNearestCombatant", "", "", arguments[0]
    @getNearestCombatant()

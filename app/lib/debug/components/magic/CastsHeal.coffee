Component = require 'lib/world/component'

module.exports = class CastsHeal extends Component
  @className: 'CastsHeal'

  constructor: (config) ->
    super config
    @_healSpell = name: 'heal', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, health: @health
    delete @health
    delete @cooldown
    delete @specificCooldown
    delete @range

  attach: (thang) ->
    super thang
    thang.addSpell @_healSpell

  getTarget_heal: ->
    return null unless friends = @getFriends?()
    bestFriend = null
    bestFriendValue = 0
    healRangeSquared = @spells.heal.range * @spells.heal.range
    # TODO: don't try to heal dead people?
    for friend in friends when friend.health < friend.maxHealth
      amountToBeHealed = Math.min friend.maxHealth - friend.health, @spells.heal.health
      continue if amountToBeHealed < @spells.heal.healAmount / 2 and friend.health > friend.maxHealth / 2
      inRange = @distanceSquared(friend) <= healRangeSquared
      healValue = amountToBeHealed / (1 + friend.health / friend.maxHealth)
      healValue /= 10 unless inRange
      if healValue > bestFriendValue
        bestFriendValue = healValue
        bestFriend = friend
    bestFriend
    
  perform_heal: ->
    return if @target.dead
    @target.health = Math.min @target.maxHealth, @target.health + @spells.heal.health
    if @target.effects
      # Add a heal mark just for the animation
      @target.effects = (e for e in @target.effects when e.name isnt 'heal')
      @target.addEffect {name: 'heal', duration: 0.5, reverts: true, setTo: true, targetProperty: 'beingHealed'}

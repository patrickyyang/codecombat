Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class Chieftains extends Component
  @className: 'Chieftains'
  chooseAction: ->
    return if @isProgrammable and (@programmableMethods.chooseAction or @programmableMethods.plan)
    enemies = (e for e in @getEnemies() when (e.type not in ['ice-yak', 'sand-yak', 'cow']) or e.target?.team is @team)
    hero = @getNearest (t for t in enemies when /Hero Placeholder/.test t.id)
    @mainEnemy = @getNearest(enemies) or @mainEnemy
    if @mainEnemy and hero and @distance(hero) < 1.1 * @distance(@mainEnemy) + 2
      @mainEnemy = hero  # Target the hero if it's almost the closest enemy
      
    # Dodge the nearest incoming artillery shell
    missile = @getNearest @getEnemyMissiles()
    if missile and missile.type is 'shell' and missile.shooter?.type is 'artillery'
      dir = new Vector 0, 0, 0
      dx = (@pos.x - missile.targetPos.x) or 0.1
      dy = (@pos.y - missile.targetPos.y) or 0.1
      d2 = @pos.distanceSquared(missile.targetPos) or 0.01
      if d2 < 120 and missile.velocity.z < 0
        maxZ = 16
        dir.x += 10 * dx / d2 * (maxZ - missile.pos.z) / maxZ
        dir.y += 10 * dy / d2 * (maxZ - missile.pos.z) / maxZ
        if dir.magnitude() > 1
          fleePos = @pos.copy().add dir.normalize().multiply 5
          if @isPathClear @pos, fleePos
            @move fleePos
            return

    # Warcry or attack if there is an enemy.    
    if @mainEnemy
      @battleHasStarted = true
      if @isReady 'warcry'
        @warcry()
      else
        @attack @mainEnemy
      
  update: ->
    # Command friendly troops for advanced tactics while we are still alive.
    # TODO: make sure that troops revert to auto-attacking when we die.
    return if @dead
    return if @isProgrammable and (@programmableMethods.chooseAction or @programmableMethods.plan)
    @mainEnemy = null if @mainEnemy?.dead
    friends = @getFriends()
    unless @battleHasStarted
      for friend in friends
        if (friend.action isnt 'idle' or friend.health < friend.maxHealth) and @canSee friend
          @battleHasStarted = true
          break
    return unless @battleHasStarted  
    witches = (t for t in friends when t.type is 'witch')
    gettingGrown = false
    nextMainEnemy = null
    nextMainEnemyDistanceSq = Infinity
    for friend in friends when friend.type in @commandableTypes
      friendDistanceSq = @distanceSquared friend
      enemy = friend.getNearestEnemy() or @mainEnemy
      enemyDistanceSq = friend.distanceSquared enemy if enemy
      mainEnemyDistanceSq = friend.distanceSquared @mainEnemy if @mainEnemy
      if not @mainEnemy and enemyDistanceSq < nextMainEnemyDistanceSq and @canSee friend
        nextMainEnemy = enemy
        nextMainEnemyDistanceSq = enemyDistanceSq
      attackRangeSq = friend.attackRange * friend.attackRange
      canFlee = not enemy or friend.maxSpeed > enemy.maxSpeed + 1
      needsHeal = friend.maxHealth > 50 and friend.health < friend.maxHealth / 5
      if canFlee and needsHeal
        # Run back and play defensive, either to defend the chieftain or to get healed by a witch.
        @command friend, 'defend', friend.getNearest(witches) or @
      else if not gettingGrown and not @hasEffect('grow') and 0.5 * @maxHealth < @health < 0.8 * @maxHealth and friend.type is 'shaman' and friend.canCast('grow', @) and friendDistanceSq < Math.pow(friend.spells.grow.range, 2)
        @command friend, 'cast', 'grow', @
        gettingGrown = true
      else if enemy and canFlee and enemy.target is friend and friend.type in ['munchkin', 'thrower', 'fangrider', 'shaman'] and enemyDistanceSq < 64
        # Try to kite the enemy, either directly away from it or back towards us, if we think we can get away.
        fleePos = friend.pos.copy().subtract(enemy.pos).normalize().multiply 4
        if @isPathClear friend.pos, fleePos
          @command friend, 'move', fleePos
        else if friendDistanceSq < @distanceSquared(enemy)
          @command friend, 'defend', @
        else
          @command friend, 'attack', enemy
      else if @world.dt < @getCooldown('warcry') <= 1 and Math.pow(@warcryRange, 2) < friendDistanceSq <= Math.pow(@warcryRange + (@getCooldown('warcry') - @world.dt) * friend.maxSpeed, 2)
        # We're about to warcry, but this friend is just out of range, so move back into range to get it
        @command friend, 'move', @pos
      else if @mainEnemy and mainEnemyDistanceSq < attackRangeSq * 1.1
        @command friend, 'attack', @mainEnemy
      else if enemy
        @command friend, 'attack', enemy
    @mainEnemy ?= nextMainEnemy  # We can't personally see an enemy, but one of our minions can, so we aggro also.

  performAttack: (thang) ->
    # Do AOE damage to everything within attackRange (plus a bit)
    enemies = @getEnemies()
    for enemy in enemies when enemy isnt thang and @distance(enemy, true) < @attackRange + 1
      momentum = @getAttackMomentum enemy.pos
      enemy.takeDamage? @attackDamage, @, momentum
    null

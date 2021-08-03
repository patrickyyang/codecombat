Component = require 'lib/world/component'

module.exports = class MinesweeperReferee extends Component
  @className: 'MinesweeperReferee'
  chooseAction: ->
    @setUp() unless @didSetUp
    @controlPeasant peasant for peasant in @peasants
    @controlTrap trap for trap in @traps
    @controlHealer()
    #@checkVictory()

  setUp: ->
    @didSetUp = true
    @hero = @world.getThangByID 'Hero Placeholder'
    @healer = @world.getThangByID 'Doctor Beak'
    @healer.healQueue = []
    @healer.cowardDistance = @hero.pos.x - @healer.pos.x
    @peasants = (t for t in @world.thangs when t.type is 'peasant')
    for peasant in @peasants
      peasant.cowardDistance = @hero.pos.x - peasant.pos.x
    @spawnTraps()

  spawnTraps: ->
    @traps = []
    x = 24
    lastX = 22
    lastY = 35
    minY = 28
    maxY = 42
    while x < 58
      if @world.rand.randf() < 0.35
        y = 0
        tries = 0
        until Math.max(minY, lastY - (x - lastX)) < y < Math.min(maxY, lastY + (x - lastX))
          y = minY + @world.rand.randf() * (maxY - minY)
          ++tries
          if ++tries > 100
            y = lastY
            break
        @buildXY 'fire-trap', x, y
        lastX = x
        lastY = y
        trap = @performBuild()
        trap.attackRange = 0  # We'll manually trigger it
        trap.attackDamage = Math.max(trap.attackDamage, @hero.maxHealth / 3)
        trap.collisionCategory = 'none'
        @traps.push trap
        @buildXY 'gold-coin', x, y
        coin = @performBuild()
        trap.coin = coin
        trap.chainReacts = false
        x += 4
      else
        x += 1

  controlPeasant: (peasant) ->
    return if peasant.health <= 0
    if @hero.health > 0
      peasant.move x: Math.max(peasant.pos.x, @hero.pos.x - peasant.cowardDistance), y: peasant.pos.y
    else
      peasant.move x: 64, y: peasant.pos.y
      
  controlTrap: (trap) ->
    return unless trap.exists
    if not trap.coin.exists
      hasMove = 'move' in @hero.programmableProperties
      trap.attackRange = if hasMove then 4 else 2
      trap.mass = 500
      trap.mass = 1 if @hero.maxSpeed > 8 # Blow up less for faster heroes so they don't get blasted into later mines
    for peasant in @peasants
      if trap.distance(peasant) < 4
        trap.attackRange = 4
        trap.mass = 2000

  # Make sure that all heal requests get fulfilled.
  controlHealer: ->
    if @healer.canCast('heal') and @healer.healQueue.length > 0
      target = @healer.healQueue[0]
      if target
        if target.health < target.maxHealth
          @healer.cast('heal', target)
          @healer.say('Healed!')
        @healer.healQueue.shift()
    else if @healer.healQueue.length is 0
      @healer.move x: Math.max(@healer.pos.x, @hero.pos.x - @healer.cowardDistance), y: @healer.pos.y

  checkVictory: ->
    return if @victoryChecked

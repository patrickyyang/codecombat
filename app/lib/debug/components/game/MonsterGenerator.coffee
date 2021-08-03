Component = require 'lib/world/component'

module.exports = class MonsterGenerator extends Component
  @className: 'MonsterGenerator'

  initialize: ->
    @active = true
    @spawnDelay = 5
    @spawnRadius = 0
    @lastSpawn = 0
    @spawnType = "skeleton"
    @spawnAI = "AttacksNearest"
    @team = "ogres"

  update: ->
    @generateMonsters()

  generateMonsters: ->
    return unless @active and not @dead
    return unless game = @commander
    if (@world.age > (@lastSpawn + @spawnDelay)) or (@lastSpawn is 0)
      if @spawnRadius
        angle = @world.rand.randf() * Math.PI
        r = @world.rand.randf2(0, @spawnRadius)
        thang = game.spawnXY @spawnType, @pos.x + Math.cos(angle) * r, @pos.y + Math.sin(angle) * r
      else
        thang = game.spawnXY @spawnType, @pos.x, @pos.y
      game.attachAI thang, @spawnAI
      thang.behavior = @spawnAI
      @lastSpawn = @world.age
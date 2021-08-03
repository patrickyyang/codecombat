Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class Terrifies extends Component
  @className: "Terrifies"
  constructor: (config) ->
    super config
    @terrifyRangeSquared = @terrifyRange * @terrifyRange

  attach: (thang) ->
    terrifyAction = name: 'terrify', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions terrifyAction

  terrify: (@terrifyWords) ->
    @setAction 'terrify'
    
  fearedChooseAction: ->
    # this is what the enemy unit does while feared
    #nearestEnemy = @getNearestEnemy()
    #direction = Vector.normalize Vector.subtract(@pos, nearestEnemy.pos)
    #target = Vector.add(@pos, Vector.multiply(direction, 1000))
    #this.move(target)
    unless @fearedDirection
      @fearedDirection = new Vector(1000, 0)
      randomNum = @world.rand.randf()
      num = randomNum*Math.PI*2
      @fearedDirection.rotate(num)
    @move @fearedDirection

  update: ->
    return unless @action is 'terrify' and @act()
    @unhide?() if @hidden
    @addCurrentEvent? 'terrify'
    @sayWithoutBlocking?(@terrifyWords or "You will be exterminated!")
    for enemy in @getEnemies() when enemy.hasEffects and @distanceSquared(enemy) <= @terrifyRangeSquared
      enemy.effects = (e for e in enemy.effects when e.name isnt 'terrify')
      effects = [
        {name: 'fear', duration: @terrifyDuration, reverts: true, setTo: @fearedChooseAction, targetProperty: 'chooseAction'}
        
        # Clears targetPos at the end of the fear, or else it might break AutoTargetsNearest
        {name: 'fear', duration: @terrifyDuration, reverts: true, setTo: null, targetProperty: 'targetPos'}
      ]
      enemy.addEffect effect, @ for effect in effects
    args = [parseFloat(@pos.x.toFixed(2)),parseFloat(@pos.y.toFixed(2)),parseFloat(@terrifyRange.toFixed(2)),'#800000']
    @addCurrentEvent "aoe-#{JSON.stringify(args)}"
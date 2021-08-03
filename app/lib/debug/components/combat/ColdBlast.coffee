Component = require 'lib/world/component'

module.exports = class ColdBlast extends Component
  @className: 'ColdBlast'
  
  constructor: (config) ->
    super config
    @coldBlastRangeSquared = @coldBlastRange * @coldBlastRange
  
  attach: (thang) ->
    coldBlastAction = name: 'cold-blast', cooldown: @cooldown, specificCooldown: @specificCooldown, duration: @freezeDuration, freezeHeroSlowFactor: (1 / Math.sqrt(1 + @freezeDuration))
    delete @cooldown
    delete @specificCooldown
    delete @freezeDuration
    super thang
    thang.addActions coldBlastAction
  
  coldBlast: () ->
    @setAction 'cold-blast'
    @block?()

  performColdBlast: () ->
    @brake?()
    @sayWithoutBlocking? 'Freeze!'
    targets = @getEnemies()
    freezeDuration = @actions['cold-blast'].duration
    freezeHeroSlowFactor = @actions['cold-blast'].freezeHeroSlowFactor
    for target in targets when @distanceSquared(target) < @coldBlastRangeSquared
      if /hero\ placeholder/i.test target.id
        target.effects = (e for e in target.effects when e.name isnt 'slow')
        effects = [
          {name: 'slow', duration: freezeDuration, reverts: true, setTo: true, targetProperty: 'isSlowed'}
          {name: 'slow', duration: freezeDuration, reverts: true, factor: freezeHeroSlowFactor, targetProperty: 'maxSpeed'}
          {name: 'slow', duration: freezeDuration, reverts: true, factor: @freezeHeroSlowFactor, targetProperty: 'actionTimeFactor'}
        ]
        
      else
        target.effects = (e for e in target.effects when e.name isnt 'freeze')
        
        effects = [
          {name: 'freeze', duration: freezeDuration, reverts: true, setTo: true, targetProperty: 'isFrozen'}
          {name: 'freeze', duration: freezeDuration, reverts: true, setTo: @freezedChooseAction, targetProperty: 'chooseAction'}
          {name: 'freeze', duration: freezeDuration, reverts: true, targetProperty: 'commander', setTo: @}
        ]
      target.brake?()
      target.addEffect effect, @ for effect in effects
    @unblock?()
    @setAction 'idle'
  
  
    # Drawing attack
    X = parseFloat(@pos.x.toFixed(2))
    Y = parseFloat(@pos.y.toFixed(2))
    radius = parseFloat(@coldBlastRange.toFixed(2))
    color = '#629CED'

    args = [X, Y, radius, color] #, endAngle, startAngle]
    @addCurrentEvent "aoe-#{JSON.stringify(args)}"

  freezedChooseAction: ->
    @setAction "idle"
    @intent = null
    @brake?()
    return

  update: ->
    if @action is 'cold-blast' and @act()
      @performColdBlast()
      

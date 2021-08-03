Component = require 'lib/world/component'

module.exports = class GravityVortex extends Component
  
  constructor: (config) ->
    super config
    @gravitionalThresholdSquared = @gravitionalThreshold * @gravitionalThreshold
    @gravitionalInnerRadius = @gravitionalInnerRadius * @gravitionalInnerRadius
    @summonTime = 1
  
  attach: (thang) ->
    super thang
    thang.allianceSystem = thang.world.getSystem("Alliance")
    summonAction = name: 'summon', cooldown: @summonTime, specificCooldown: 0
    thang.addActions summonAction
  
  chooseAction: ->
    #console.log(@world.age, @, @summonEndAt, @action)
    if not @isSummoned and @action is "idle"
      @actionBeforeSummoned = @action
      @setAction "summon"
      @isSummoned = true
      @summonEndAt = @world.age + @summonTime
      return
    if @summonEndAt and (@world.age > @summonEndAt)
      @summonEndAt = null
      @setAction @actionBeforeSummoned
    for th in @allianceSystem.allAlliedThangs when th.isMissile or th.isAttackable
      continue if @gravitionalMaster and th is @gravitionalMaster
      squared = @distanceSquared(th)
      dir = @pos.copy().subtract(th.pos).normalize()
      if squared <= @gravitionalThresholdSquared
        dir.multiply(@gravitionalInnerSpeed)
        th.velocity = dir.copy()
        th.velocity.x = dir.y
        th.velocity.y = -dir.x
        th.velocity.z = 0
        th.pos.z = @depth
        th.takeDamage?(@gravitionalDPS * @world.dt, @spawnedBy)
        @performDaze(th) unless th.isMissile or (not th.hasEffects) or th.hasEffect?("daze") or th.isProgrammable
      if squared >= @gravitionalInnerRadius
        force = @gravitionalCoefficient / (squared * (th.mass? || 1))
        continue unless force > 0.1
        # less force for heroes
        if th.isProgrammable
          force *= @gravitionalHeroRatio
        dir.normalize().multiply(force * @world.dt)
        if th.velocity
          th.velocity.add(dir)
        else
          th.velocity = dir
        
  
  performDaze: (target) ->
    return unless target.effects
    onRevert = ->
      target.setTarget null
      target.setAction 'idle'
      target.movedOncePos = null
      target.castOnceTarget = null
      target.clearAttack?()
    target.effects = (e for e in target.effects when e.name isnt 'confuse')
    effects = [
      {name: 'confuse', duration: @lifespan, reverts: true, setTo: @dazedChooseAction, targetProperty: 'chooseAction', onRevert: onRevert}
      {name: 'confuse', duration: @lifespan, reverts: true, setTo: null, targetProperty: 'targetPos'}
      {name: 'daze', duration: @lifespan, reverts: true, targetProperty: 'commander', setTo: @}
      
    ]
    target.addEffect effect, @ for effect in effects
    target.endCurrentPlan?()
  
  dazedChooseAction: ->
    # This is what the enemy unit does while confused.
    @setAction("idle")
    @sayWithoutBlocking? 'Aaaa!', 1

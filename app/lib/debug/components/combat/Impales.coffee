Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class Impales extends Component
  @className: 'Impales'

  attach: (thang) ->
    impaleAction = name: 'impale', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions impaleAction

  impale: (targetOrPos) ->
    @setAction 'impale'
    @impaleTarget = targetOrPos
    return @block?() unless @commander
    
  update: ->
    @updateMissiles()
    return unless @action is 'impale'
    @performImpale() if @action is 'impale' and @act()
    @unblock?()
    
  performImpale: ->
    @unhide?() if @hidden
    targetPos = @impaleTarget?.pos ? @impaleTarget ? (new Vector(1, 0).rotate(@rotation))
    targetPos = new Vector targetPos.x, targetPos.y, targetPos.z unless targetPos.isVector
    dir = Vector.subtract(targetPos, @pos).normalize()
    dir.z = 0
    @velocity?.add dir.copy().multiply -@impaleRecoilMass / @mass
    @sayWithoutBlocking? @impalePhrase ? 'Take THAT!'

    unless @impaleMissileSpriteName
      missileThang = @world.getThangByID @impaleMissileThangID
      unless missileThang
        console.log @id, "Impales problem: couldn't find missile to shoot for ID", @impaleMissileThangID
        return
      @impaleMissileSpriteName = missileThang.spriteName
      @impaleMissileComponents = _.cloneDeep missileThang.components
    return unless @impaleMissileSpriteName

    missile = @spawn @impaleMissileSpriteName, @impaleMissileComponents, null, 'Impaling ' + @impaleMissileSpriteName
    missile.setExists true
    missile.pos = Vector.add @pos, {x: 0, y: 0, z: missile.pos.z}, true  # Physical pos as offset to shooter pos, but only in z dimension
    missile.targetPos = missile.pos.copy().add(dir.copy().multiply(1000))
    missile.velocity = dir.copy().multiply missile.maxSpeed
    missile.maintainsElevation = -> true
    missile.rotation = missile.velocity.heading() % (2 * Math.PI)
    missile.hasRotated = true
    missile.targetsHit = []
    missile.addCurrentEvent? 'launch'
    @impaleMissiles ?= []
    @impaleMissiles.push missile

  updateMissiles: ->
    return unless @impaleMissiles
    for missile in (@impaleMissiles ? []) when missile.exists
      missile.rotation = missile.velocity.heading() % (2 * Math.PI)
      for thang in @world.getSystem("Combat").attackables
        if thang isnt @ and not (thang.id in missile.targetsHit) and missile.intersects(thang)
          momentum = Vector.subtract(thang.pos, @pos).normalize(true)
          momentum.z = Math.sin Math.PI / 6
          momentum.normalize(true).multiply(@impaleRecoilMass, true)
          thang.takeDamage? @impaleDamage, @, momentum
          missile.addCurrentEvent 'hit'
          missile.targetsHit.push thang.id
      # TODO: have it stop when it hits an obstacle?

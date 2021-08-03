Component = require 'lib/world/component'

module.exports = class Shoots extends Component
  @className: "Shoots"
  attach: (thang) ->
    thang.performAttackOriginal = thang.performAttack
    delete thang.performAttack
    @missileThangType = (@requiredThangTypes ? [])[0]
    thang.requiredThangTypes = (thang.requiredThangTypes ? []).concat(@requiredThangTypes ? [])
    thang.componentsForThangType @missileThangType if @missileThangType  # Make sure the Components are saved to the world's classMap.
    delete @requiredThangTypes
    super thang

  performAttack: (targetOrPos) ->
    @configureMissile() unless @missileComponents
    return unless @missileComponents
    @lastMissileShot = @spawn @missileSpriteName, @missileComponents
    @lastMissileShot.launch? @
    @brake?()
    @lastMissileShot
    
  configureMissile: ->
    if @missileThangID and missileThang = @world.getThangByID @missileThangID
      @missileComponents = _.cloneDeep missileThang.components
      @missileSpriteName = missileThang.spriteName
    else if @missileThangType
      @missileComponents = _.cloneDeep @componentsForThangType @missileThangType
      @missileSpriteName = _.find(@world.thangTypes, original: @missileThangType)?.name ? @missileThangType
    if @missileComponents?.length
      if allied = _.find(@missileComponents, (c) -> c[1].team)
        allied[1].team = @team
    else
      console.log @id, "Shoots problem: couldn't find missile to shoot for ID", @missileThangID, "or type", @missileThangType

Component = require 'lib/world/component'

module.exports = class Distracts extends Component
  @className: 'Distracts'
  
  PHRASES:
    distraction: ["BOOM!", "Here!", "Behind!", "Gold!", "Cookies!", "Free coffee!"]
    distracted: ["What?", "Where?", "Huh?"]
  
  constructor: (config) ->
    super config
    @distractionAffectRangeSquared = @distractionAffectRange * @distractionAffectRange
  
  attach: (thang) ->
    distractAction = {name: "distract", cooldown: @cooldown, specificCooldown: @specificCooldown, range: @distractionAffectRange}
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions distractAction
    thang.hearingSystem = thang.world.getSystem "Hearing"
  
  distractionNoise: () ->
    @setAction "distract"
    @block?()
  
  update: () ->
    return unless @action is "distract" and @act()
    @performDistractionNoise()
  
  performDistractionNoise: () ->
    @brake?()
    @sayWithoutBlocking? @world.rand.choice(@PHRASES.distraction), 1
    for hearer in @hearingSystem.hearers when hearer and @distanceSquared(hearer) <= @distractionAffectRangeSquared
      continue if hearer is @
      continue if @worksIdleOnly and hearer.action isnt "idle"
      continue if hearer.isDistracted
      continue if /hero\ placeholder/i.test(hearer.id ? "")
      hearer.effects = (e for e in hearer.effects when e.name isnt 'distract')
      
      effects = [
        {name: 'distract', duration: @distractionDuration, reverts: true, setTo: @distractedChooseAction.bind(hearer), targetProperty: 'chooseAction', onRevert: @onRevertDistraction.bind(hearer)}
        {name: 'distract', duration: @distractionDuration, reverts: true, setTo: true, targetProperty: 'isDistracted'}
      ]
      hearer.addEffect effect, @ for effect in effects
      hearer.endCurrentPlan?()
      hearer.sayWithoutBlocking? @world.rand.choice(@PHRASES.distracted), 1
      hearer.setTargetPos? @pos
    @unblock?()
    @setAction "idle"
  
  onRevertDistraction: ->
    @setTarget null
    @setAction 'idle'
    @movedOncePos = null
    @castOnceTarget = null
    @clearAttack?()
  
  distractedChooseAction: ->
    if @targetPos and @distanceTo(@targetPos) > 3
      @setAction "move"
    else
      @setAction "idle"
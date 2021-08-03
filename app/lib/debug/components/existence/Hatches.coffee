Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class Hatches extends Component
  @className: 'Hatches'

  attach: (thang) ->
    hatchAction = name: 'hatch', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions hatchAction

  hatch: ->
    return @handleHungryHatchWarning() unless @devouredCount
    @setAction 'hatch'
    
  update: ->
    return unless @action is 'hatch' and @act()
    toHatch = @devouredCount * @devourToHatchRatio
    for i in [0 ... toHatch]
      @toBuild = @buildables[@hatchType]
      hatched = @performBuild()
      offsetAngle = 2 * Math.PI * i / toHatch - Math.PI
      hatched.pos.add new Vector(2, 0).rotate offsetAngle
    @devouredCount = 0
  
  handleHungryHatchWarning: ->
    return unless @isProgrammable and not @handledHungryHatching and aether = @getAetherForMethod('chooseAction')
    @handledHungryHatching = true
    statementRange = aether.lastStatementRange
    message = "#{@id} can't hatch without first successfully devouring."
    fakeError = {name: "HungryHatch", message: message, toString: -> message}
    problem = aether.createUserCodeProblem type: 'runtime', level: 'info', error: fakeError, range: statementRange
    @addAetherProblemForMethod problem, 'chooseAction'

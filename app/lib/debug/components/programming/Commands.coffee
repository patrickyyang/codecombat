Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Commands extends Component
  @className: "Commands"
  
  constructor: (config) ->
    super config
    @_commandableTypes = @commandableTypes ? []
    @_commandableMethods = @commandableMethods ? []
    delete @commandableTypes
    delete @commandableMethods

  attach: (thang) ->
    super thang
    thang.commandableTypes = _.union (thang.commandableTypes or []), @_commandableTypes
    thang.commandableMethods = _.union (thang.commandableMethods or []), @_commandableMethods

  command: (minion, methodName, args...) ->
    unless minion?.isThang
      throw new ArgumentError "#{@id} needs something to command.", "command", "minion", "unit", minion
    unless minion.team is @team
      throw new ArgumentError "#{@id} (team #{@team}) can't command #{minion.id} (team #{minion.team}).", "command", "minion", "unit", minion
    if @commandableTypes?.length and not (minion.type in @commandableTypes)
      throw new ArgumentError "#{@id} can't command type #{minion.type} (only types: #{@commandableTypes}).", "command", "minion", "unit", minion
    unless _.isString methodName
      throw new ArgumentError "Call a method on #{minion.id}, like '#{@commandableMethods[0]}'.", "command", "methodName", "string", methodName
    unless methodName in @commandableMethods
      throw new ArgumentError "#{methodName} isn't one of the commands, like '#{@commandableMethods[0]}'.", "command", "methodName", "string", methodName
    unless minion[methodName]
      throw new ArgumentError "#{minion.id} has no #{methodName} command.", "command", "methodName", "string", methodName
    return if minion.dead
    return if minion.hasEffect?('confuse') or minion.hasEffect?('fear')
    minion.specificAttackTarget = minion.defendTarget = minion.castingCommandedSpellTarget = minion.hasCastCommandedSpell = null  # Make sure to forget any previous orders
    minion.commander = @
    minion[methodName](args...)


Component = require 'lib/world/component'

module.exports = class AutoCasts extends Component
  @className: "AutoCasts"
  chooseAction: ->
    return if @commander and not @commander.dead
    return if @gameEntity # Disable default AI in GameDev levels.
    for spellName, spell of @spells when not @spellHeats[spellName]
      spellTarget = @['getTarget_' + spell.name]?()
      if spellTarget and @canCast spell.name, spellTarget
        return @cast spell.name, spellTarget
    if @action is 'cast'
      @setTarget null  # null out the target, since we cast a spell
Component = require 'lib/world/component'

module.exports = class TalksToSelf extends Component
  @className: "TalksToSelf"
  chooseAction: ->
    s = @action
    if @target
      s += " " + @target.id
    else if @targetPos
      s += " " + @targetPos.toString()
    @say s
Component = require 'lib/world/component'

module.exports = class AnnouncesLoops extends Component
  @className: 'AnnouncesLoops'
  
  onAetherYield: (yieldValue) ->
    return unless yieldValue is 'simple loop'
    @simpleLoopCount ?= 0
    ++@simpleLoopCount
    times = if @simpleLoopCount > 1 then 'times' else 'time'
    @sayWithoutBlocking "Repeating loop, #{@simpleLoopCount} #{times}"

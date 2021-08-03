Component = require 'lib/world/component'

module.exports = class DestroyHandler extends Component
  @className: 'DestroyHandler'

  attach: (thang) ->
    super thang
    # Helper game mechanic for Game Dev newbies. 
    # thang is the mcp
    thang.fn ?= {}
    thang.fn.destroy = @destroyHandler
    
  destroyHandler: (target) -> (event) ->
    target ?= event.target
    if target
      target.esper_destroy?()
    
Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'

# AI System and Moves Component will take care of actually doing the pathfinding stuff.
module.exports = class FindsPaths extends Component
  @className: 'FindsPaths'
  findsPaths: true
  
  getNavGrid: ->
    @aiSystem ?= @world.getSystem("AI")
    @aiSystem.getNavGrid()
    
  isPathClear: (start, end, targetThang, ignoreHazards=false) ->
    for [argName, arg] in [['start', start], ['end', end]]
      if not arg
        throw new ArgumentError "Pass an {x: number, y: number} object for the #{argName} position.", "isPathClear", argName, "object", arg
      arg = arg.pos if arg.pos
      for k in ["x", "y", "z"]
        unless (_.isNumber(arg[k]) and not _.isNaN(arg[k]) and arg[k] isnt Infinity) or (k is "z" and not arg[k]?)
          throw new ArgumentError "Pass an {x: number, y: number} object for the #{argName} position.", "isPathClear", argName, "object", arg
    if end.isThang and not targetThang
      targetThang = end
    start = start.pos if start.pos
    end = end.pos if end.pos
    @aiSystem ?= @world.getSystem "AI"
    @aiSystem.isPathClear start, end, targetThang, ignoreHazards
    
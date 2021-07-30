System = require 'lib/world/system'

module.exports = class Targeting extends System
  constructor: (world, config) ->
    super world, config

  update: ->
    hash = 0
    return hash
    
  finish: (thangs) ->
    for thang in _.filter thangs, '_allTargets'
      if Float32Array?
        thang.allTargets = new Float32Array thang._allTargets
      else
        thang.allTargets = thang._allTargets
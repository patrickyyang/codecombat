System = require 'lib/world/system'

module.exports = class Physics extends System
  constructor: (world, config) ->
    super world, config

  update: ->
    hash = 0
    return hash
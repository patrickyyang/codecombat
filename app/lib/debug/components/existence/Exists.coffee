Component = require 'lib/world/component'

module.exports = class Exists extends Component
  @className: 'Exists'
  exists: true  # Whether the Thang should be drawn and is currently in the World. Use setExists; don't set directly.

  # We would define these stubs, but the "inheritance" is actually slow, so we'll only implement as needed.
  #initialize: ->
  #update: ->

  setExists: (exists) ->
    return if exists is @exists
    @exists = exists
    @keepTrackedProperty 'exists'
    @updateRegistration()

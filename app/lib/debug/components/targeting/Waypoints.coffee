Component = require 'lib/world/component'

module.exports = class Waypoints extends Component
  @className: "Waypoints"
  constructor: (config) ->
    super config
    @waypoints = @waypoints?.slice() ? []  # copy
    
  setWaypoints: (waypoints) ->
    @waypoints = waypoints.slice()
    @finishedWaypoints = false
    
  update: ->
    targetPos = @getTargetPos()
    if targetPos
      switchTargets = @pos.distance(targetPos) < 1
    else
      switchTargets = not @finishedWaypoints
    return unless switchTargets
    if @waypoints.length
      @setTargetPos @waypoints.shift()
      unless @waypoints.length
        @finishedWaypoints = true
    else if @finishedWaypoints
      @setTarget null

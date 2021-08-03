Component = require 'lib/world/component'

module.exports = class Patrols extends Component
  @className: 'Patrols'
  constructor: (config) ->
    super config
    @patrolSpeedRatio ?= 0.25

  chooseAction: ->
    return unless @shouldPatrol
    return if @patrolPoints.length is 0
    return if @dead
    @patrol @patrolPoints unless @target and not @target.dead
    
  patrol: (@patrolPoints) ->
    @patrolIndex ?= 0
    return if @patrolIndex >= @patrolPoints.length
    d = @pos.distance @patrolPoints[@patrolIndex]
    if d < @moveThreshold
      @patrolIndex = (@patrolIndex + 1) % @patrolPoints.length
    @currentSpeedRatio = @patrolSpeedRatio
    @move @patrolPoints[@patrolIndex]
    
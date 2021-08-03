Component = require 'lib/world/component'

module.exports = class Decoy extends Component
  @className: 'Decoy'
  constructor: (config) ->
    super config
    @lureRangeSquared = @lureRange * @lureRange
  
  chooseAction: ->
    return if @inactive
    if @move
      # Flee away from original position.
      @spawnPos ?= @builtBy?.pos ? @pos
      @fleeDirection ?= @pos.copy().subtract(@spawnPos).normalize()
      @fleeDirection.add({x: 1, y: 0}).rotate(@world.rand.randf() * 2 * Math.PI) if @fleeDirection.isZero()
      @move @pos.copy().add(@fleeDirection.copy().multiply(10))
    
    # Make all targeters within range attack us.
    for t in @world.thangs when t.setTarget and t.exists and t.attack and t.superteam isnt @superteam and t.canSee?(@) and @distanceSquared(t) < @lureRangeSquared
      t.attack @

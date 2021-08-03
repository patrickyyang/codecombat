Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class CastsFear extends Component
  @className: 'CastsFear'

  constructor: (config) ->
    super config
    @_fearSpell = name: 'fear', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range, duration: @duration
    delete @cooldown
    delete @specificCooldown
    delete @range
    delete @duration
    

  attach: (thang) ->
    super thang
    thang.addSpell @_fearSpell
    
  perform_fear: ->
    @target.effects = (e for e in @target.effects when e.name isnt 'fear')
    target = @target
    onRevert = ->
      target.setTarget null
      target.setAction 'idle'
      target.movedOncePos = null
      target.castOnceTarget = null
      target.clearAttack?()
    duration = @spells.fear.duration
    if /Hero Placeholder/.test @target.id
      duration /= 2
    effects = [
      {name: 'fear', duration: duration, reverts: true, setTo: @fearedChooseAction, targetProperty: 'chooseAction', onRevert: onRevert}
      {name: 'fear', duration: duration, reverts: true, setTo: null, targetProperty: 'targetPos'}
    ]
    @target.addEffect effect, @ for effect in effects
    @unhide?() if @hidden

  fearedChooseAction: ->
    # This is what the enemy unit does while feared.
    @sayWithoutBlocking? 'Eeek!'
    if @move and @actions?.move
      @fearedDirection ?= new Vector(1000, 0).rotate @world.rand.randf() * Math.PI * 2
      @move @fearedDirection
    
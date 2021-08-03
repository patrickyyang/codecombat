Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

{ArgumentError} = require 'lib/world/errors'

module.exports = class Backstabs extends Component
  @className: 'FreezingBackstabs'

  performBackstab: ->
    @backstabWasSuccess ?=  @hidden or (@pos.distanceSquared(@target.pos) < @pos.distanceSquared(Vector.add @target.pos, new Vector(1, 0).rotate(@target.rotation ? 0)))
    if @backstabWasSuccess or not @freezeOnSuccessOnly
      if /hero\ placeholder/i.test @target.id
        @target.effects = (e for e in @target.effects when e.name isnt 'slow')
        effects = [
          {name: 'slow', duration: @freezeDuration, reverts: true, setTo: true, targetProperty: 'isSlowed'}
          {name: 'slow', duration: @freezeDuration, reverts: true, factor: @freezeHeroSlowFactor, targetProperty: 'maxSpeed'}
          {name: 'slow', duration: @freezeDuration, reverts: true, factor: @freezeHeroSlowFactor, targetProperty: 'actionTimeFactor'}
        ]
        @target.addEffect effect, @ for effect in effects
      else
        @target.effects = (e for e in @target.effects when e.name isnt 'freeze')
        effects = [
          {name: 'freeze', duration: @freezeDuration, reverts: true, setTo: true, targetProperty: 'isFrozen'}
          #{name: 'freeze', duration: @freezeDuration, reverts: true, setTo: 0, targetProperty: 'maxSpeed'}
          {name: 'freeze', duration: @freezeDuration, reverts: true, setTo: @freezedChooseAction, targetProperty: 'chooseAction'}
          {name: 'freeze', duration: @freezeDuration, reverts: true, targetProperty: 'commander', setTo: @}
        ]
        @target.brake?()
        @target.addEffect effect, @ for effect in effects

  
  freezedChooseAction: ->
    @setAction "idle"
    @intent = null
    #@act?()
    @brake?()
    return
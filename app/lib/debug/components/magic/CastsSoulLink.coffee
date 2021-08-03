Component = require 'lib/world/component'

# TODO:
# Add forbidden link Thang types (artillery?, arrow-tower, etc)
  # Skipping this one, since stuff like arrow-tower cannot be afflicted with effects which forbids this.
# Add warnings for bad arguments (linking to an enemy, linking to a dead unit, linking to a forbidden type)
  # Blocked: Waiting on warnings instead of errors.
# Implement a unique graphic for soul-linking.
  # Blocked: Waiting on custom graphic.

{ArgumentError} = require 'lib/world/errors'

module.exports = class CastsSoulLink extends Component
  @className: 'CastsSoulLink'
  forbiddenLinkers = [];
  SOUL_LINK_RANGE = 10;
  constructor: (config) ->
    super config
    @_soulLinkSpell = name: 'soul-link', cooldown: @cooldown, specificCooldown: @specificCooldown, range: @range
    SOUL_LINK_RANGE = @range
    delete @cooldown
    delete @specificCooldown
    delete @range
    
   attach: (thang) ->
    super thang
    thang.addSpell @_soulLinkSpell
    
  'perform_soul-link': ->
    # If a 3rd Argument, use that as a target.
    # Otherwise, use the caster.
    @linkB = @castArguments?[0] or @
    @linkA = @target
    
    if @linkA is @linkB
      # Can't link to itself.
      return
    if @linkB.team isnt @team or @linkA.team isnt @team
      # One of the links is on the enemy team.
      return
    if @linkB.health <= 0 or @linkA.health <= 0
      # One link has no health.
      return
    if @linkA.type in forbiddenLinkers or @linkB.type in forbiddenLinkers
      # One of the links is in the Forbidden Linkers array.
      # Currently blocked by some units not having effects.
      return
    if @distanceTo(@linkA) > SOUL_LINK_RANGE or @distance(@linkB) > SOUL_LINK_RANGE
      # One of the links is too far.
      return
    @applySoulLink()
    
  applySoulLink: ->
    # Include a reference to the old original takeDamage function
    # Do not reference if the originalTakeDamage function is stored.
    @linkA.originalTakeDamage = @linkA.originalTakeDamage or @linkA.takeDamage
    @linkB.originalTakeDamage = @linkB.originalTakeDamage or @linkB.takeDamage
    
    # Update each link's linked targets.
    @linkA.linkTargets = _.union (@linkA.linkTargets or [@linkA]), (@linkB.linkTargets or [@linkB])
    
    # Set all link's.linkTargets to @linkA's.linkTargets
    link.linkTargets = @linkA.linkTargets for link in @linkA.linkTargets;
    
    # Remove all existing soul-link effects.
    @linkA.effects = (e for e in @linkA.effects when e.name isnt 'soul-link')
    @linkB.effects = (e for e in @linkB.effects when e.name isnt 'soul-link')
    
    # While under the effects of soul-link, the way a target takes damage is different.
    @linkA.addEffect {name: 'soul-link', duration: 9001, reverts: true, setTo: @linkedTakeDamage, targetProperty:'takeDamage'}
    @linkB.addEffect {name: 'soul-link', duration: 9001, reverts: true, setTo: @linkedTakeDamage, targetProperty:'takeDamage'}
    
    # Adds an floating effect to indicate a soul-link.
    # TODO: Remove this and hook a graphic to the 'soul-link' name.
    @linkA.effects = (e for e in @linkA.effects when e.name isnt 'heal')
    @linkB.effects = (e for e in @linkB.effects when e.name isnt 'heal')
    # NOTE: Do not use the name 'fear' or 'confuse' as placeholders as units with those effects cannot be commanded.
    @linkA.addEffect {name: 'control', duration: 9001, reverts: true, setTo: true, targetProperty: 'soulLinked'}
    @linkB.addEffect {name: 'control', duration: 9001, reverts: true, setTo: true, targetProperty: 'soulLinked'}
    
  linkedTakeDamage: (damage, attacker, momentum=null, fromSource=true) ->
    liveLinks = _.filter (@linkTargets), (_l) -> return _l?.health > 0
    if fromSource
      linkTarget?.takeDamage (damage / (liveLinks?.length || 1)), attacker, momentum, false for linkTarget in liveLinks
    else
      @originalTakeDamage damage, attacker, momentum
    
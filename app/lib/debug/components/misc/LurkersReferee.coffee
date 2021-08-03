Component = require 'lib/world/component'

module.exports = class LurkersReferee extends Component
  @className: 'LurkersReferee'

  setUpLevel: ->
    @world.getThangByID('Ghuk').wanderRegion = @rectangles.GhukWander
    @world.getThangByID('Turann').wanderRegion = @rectangles.TurannWander
    @world.getThangByID('Nazgareth').wanderRegion = @rectangles.NazgarethWander
    @world.getThangByID('Randall').wanderRegion = @rectangles.RandallWander
    @world.getThangByID('Langthok').wanderRegion = @rectangles.LangthokWander
    @world.getThangByID('Arngotho').wanderRegion = @rectangles.ArngothoWander

  controlOgres: (ogres) ->
    for o in ogres
      e = o.findNearestEnemy()
      if e and e.team == 'humans' and (o.distanceTo(e) < 8 or o.health < o.maxHealth)
        o.attack(e)
        @cancelSleep o
      else
        o.actionHeats.all = 2 * @world.dt
        @cancelSleep o
        o.addEffect {name: 'sleep', duration: @world.dt, reverts: true, setTo: true, targetProperty: 'asleep'}
    for o in @world.thangs when o.team is 'ogres' and o.type is 'shaman' and o.dead
      @cancelSleep o

  cancelSleep: (ogre) ->
    effect.timeSinceStart = 9001 for effect in ogre.effects when effect.name is 'sleep'
    ogre.updateEffects()

  controlNeutral: (yaks) ->
    for y in yaks
      if y.action is 'attack' or y.enraged
        y.enraged = true
        continue
      @doWander(y)

  doWander: (mob) ->
    return if not mob.wanderRegion
    if not mob.wanderPoint
      mob.wanderPoint = @pickPointFromRegions([mob.wanderRegion])
    mob.move(mob.wanderPoint)
    if mob.distanceTo(mob.wanderPoint) < 4
      mob.wanderPoint = null

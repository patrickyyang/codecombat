Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class HarrowlandReferee extends Component
  @className: 'HarrowlandReferee'
  chooseAction: ->
    if @world.age > 0 and not @didPostSetUp then @postSetUp()

  postSetUp: ->
    @didPostSetUp = true

    # Don't attack yaks.
    for yak in @world.thangs when yak.type is 'sand-yak'
      yak.isAttackable = false

    # Scale minion wave power based on the average the of the players' health.
    f = @calcMinionWavePower()
    for wave in @waves
      continue if wave.name != 'minionsWest'
      wave.scaledPower *= f

    # Spawn 2 of each minion, one for each team.
    @spawnWaveNamed('minionsWest')
    for mw in @built when mw.type != 'sand-yak'
      # mirror positions for a fair fight.
      mwMinX = @rectangles.minionsWest.vertices()[0].x
      meMaxX = @rectangles.minionsEast.vertices()[2].x
      np = new Vector(meMaxX - (mw.pos.x - mwMinX), mw.pos.y)
      me = @instabuild(@getEastBuildType(mw.type), np.x, np.y)

  # Minions on the east/ogre side use the template build types.
  getEastBuildType: (otype) ->
    if otype not in @world.getSystem('Existence').buildTypePower
      return otype + ['-f-east', '-m-east'][@world.rand.rand(2)]
    return otype

  calcMinionWavePower: ->
    h0 = @hero.maxHealth
    h1 = @hero2.maxHealth
    havg = (h0 + h1) / 2
    return Math.max(1.0, havg / 500)

  controlNeutral: (yaks) ->
    for yak in yaks
      continue if yak.action is 'attack'
      
      e = yak.findNearestEnemy()
      if e and yak.distanceTo(e) < 5
        yak.attack(e)
        return

      if not yak.wanderPoint
        yy = if yak.pos.y > 32 then 20 else 48
        yak.wanderPoint = new Vector(yak.pos.x, yy)
      if yak.wanderPoint
        yak.move(yak.wanderPoint)
      if yak.distanceTo(yak.wanderPoint) < 5
        yak.wanderPoint = null

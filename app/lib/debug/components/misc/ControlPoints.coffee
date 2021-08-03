Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

_controlPoints = []

module.exports = class ControlPoints extends Component
  @className: 'ControlPoints'

  constructor: (config) ->
    super config
    @captureRadiusSquared = @captureRadius * @captureRadius
    @sprites = [] if @manager

  # TODO Move to config
  addControlPoint: (id, pos, team, namesByTeam) ->
    return unless @manager
    @sprites.push h = @instabuild 'control-point-humans', pos.x, pos.y
    @sprites.push o = @instabuild 'control-point-ogres', pos.x, pos.y
    @sprites.push n = @instabuild 'control-point', pos.x, pos.y
    h.team = 'humans'
    o.team = 'ogres'
    n.team = undefined
    h.id = "#{id} Control Point (Humans)"
    o.id = "#{id} Control Point (Ogres)"
    n.id = "#{id} Control Point"
    h.pos = o.pos = n.pos = pos.copy()
    for sprite in [h, o, n]
      sprite.setExists sprite.team is team
      sprite.addTrackedProperties ['pos', 'Vector']
      sprite.keepTrackedProperty 'pos'
    _controlPoints.push id: id, pos: pos.copy(), team: team or null, namesByTeam: namesByTeam, toString: (-> @id)

  getControlPoints: ->
    points = (_.clone point for point in _controlPoints)
    for point in points
      point.name = point.namesByTeam?[@team] or point.id
      delete point.namesByTeam
    corner = if @team is 'humans' then new Vector(4, 4) else new Vector(116, 96)
    points = _.sortBy points, (p) -> corner.distanceSquared p.pos
    points

  getControlPointsMap: ->
    _.indexBy @getControlPoints(), 'name'

  # TODO: Custom level actions for managing income?
  updateControlPoints: ->
    return unless @manager
    
    attackables = (t for t in @world.getSystem("Combat").attackables when t.team isnt 'neutral')
    incomes = humans: 0, ogres: 0
    for point, index in _controlPoints
      team = undefined
      nearest = _.min attackables, (thang) -> point.pos.distanceSquared thang.pos
      if nearest and nearest.pos and point.pos.distanceSquared(nearest.pos) < @captureRadiusSquared
        team = nearest.team
        incomes[team] += @income
      _controlPoints[index].team = team or null
      for sprite in @sprites when sprite.pos.equals point.pos
        sprite.setExists sprite.team is team
    @world.getSystem("Inventory").teamGold[team].income = income for team, income of incomes

  chooseAction: ->
    @updateControlPoints()
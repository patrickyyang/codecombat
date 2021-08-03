Component = require 'lib/world/component'

module.exports = class CrissCrossPlayer extends Component
  @className: "CrissCrossPlayer"
  teamColors: 
    humans: '#ff0000'
    ogres: '#0000ff'

  attach: (thang) ->
    super thang
    thang.addTrackedProperties ['round', 'number']
    thang.addTrackedFinalProperties 'turns', 'tileGrid'
    thang.addTrackedProperties ['tilesOwned', 'array'], ['myTiles', 'array'], ['opponentTiles', 'array']
    thang.keepTrackedProperty prop for prop in ['tilesOwned', 'myTiles', 'opponentTiles']

  setMap: (@map) -> @updateGrid()
  setTileGroups: (@tileGroups) ->
  setTurns: (@turns) ->

  setRound: (@round) ->
    @keepTrackedProperty 'round'
    if @round  # Fast-forward mode after the first round.
      @currentSpeedRatio = 1
  
  hear: (speaker, message, data) ->
    # "data" is the referee thang, if it's an actual bid request.
    return if speaker.team isnt 'neutral'
    return if (not data) || (data.currentTileGroup is undefined)
    submission = @makeBid(data.currentTileGroup)
    unless submission
      @say "No bid", submission
      return

    if _.isNumber(submission.gold)
      submission.gold = Math.round(submission.gold);
    else
      submission.gold = 0
    @say (submission.desiredTile?.id ? "???") + " for " + submission.gold + " gold!", submission

    tile = submission.desiredTile
    return unless tile?.id
    nodeThang = @getThangForNodeID(tile.id)
    color = @teamColors[@team]
    offset = if @team is 'humans' then -1.5 else 1.5
    args = [parseFloat(nodeThang.pos.x+offset),parseFloat(nodeThang.pos.y),1.5,color]
    @addCurrentEvent "aoe-#{JSON.stringify(args)}"

    
  updateAPIs: ->
    @updateTilesProperties()
    
  updateTilesProperties: ->
    @tilesOwned = (tile for tile in _.values(@map) when tile.owner)
    @tilesOwned = _.sortBy @tilesOwned, 'turnWon'
    @myTiles = (tile for tile in @tilesOwned when tile.owner is @team)
    @opponentTiles = (tile for tile in @tilesOwned when tile.owner isnt @team)

  getTile: (x, y) -> return @tileGrid[x][y]

  # Give this a tile and it will highlight it
  highlightTile: (tile) ->
    nodeThang = @getThangForNodeID(tile.id)
    color = @teamColors[@team]
    yOffset = if @team is 'humans' then -2.5 else 2.5
    args = [parseFloat(nodeThang.pos.x),parseFloat(nodeThang.pos.y+yOffset),1.0,color]
    @addCurrentEvent "aoe-#{JSON.stringify(args)}"

  # the referee uses a map system, but looks like the grid will be
  # more intuitive to players, so build that and expose that instead
  updateGrid: ->
    @tileGrid = []
    for tile in _.values(@map)
      @tileGrid[tile.x] ?= []
      @tileGrid[tile.x][tile.y] ?= []
      @tileGrid[tile.x][tile.y] = tile
      
  makeBidValidateReturn: (bid) ->
    if bid and bid.hash
      # Workaround for Lua's stuff being returned as a table
      bid.gold ?= bid.hash.gold
      bid.desiredTile ?= bid.hash.desiredTile
    unless _.isNull(bid) or _.isObject(bid)
      throw new Error("makeBid() should return a bid object or null, not #{bid}.")
    return null unless bid
    unless bid.gold? and _.isNumber(bid.gold) and bid.gold >= 0
      throw new Error("makeBid() should return a bid with 'gold' as an integer >= 0, not #{typeof bid.gold} #{bid.gold}.")
    if bid.desiredTile? and not (_.isObject(bid.desiredTile) and bid.desiredTile.id and bid.desiredTile.x? and bid.desiredTile.y?)
      throw new Error("makeBid() should return a bid with 'desiredTile' as a tile object, not #{typeof bid.desiredTile} #{bid.desiredTile}.")
    null
    
  getThangForNodeID: (nodeID) -> @world.getThangByID("Tile " + nodeID)
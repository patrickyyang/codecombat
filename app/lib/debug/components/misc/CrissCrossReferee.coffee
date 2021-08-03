Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

p = (x, y) -> "#{x}.#{y}"

module.exports = class CrissCrossReferee extends Component
  @className: "CrissCrossReferee"
  
  # turn states
  ASKING_STATE: 'asking'
  HEARING_STATE: 'hearing'
  WATCHING_STATE: 'watching'
  CROSSING_STATE: 'crossing'
  ALL_DONE_STATE: 'done'
  
  # game params
  HEIGHT: 7
  WIDTH: 7
  TILE_GROUP_SIZE: 7
  NUM_ROUNDS: 5
  MAX_TURNS: 40
  tileGroupLetters: ['A', 'B', 'C', 'D', 'E', 'F', 'G']
  
  # game state
  map: null
  tileGroups: null
  currentTileGroup: 'A'
  turn: 0
  round: 0
  turnsSinceChange: 0
  turnState: null
  roundScores: {humans: 0, ogres: 0}
  turns: []
  
  # timing
  durationForWatching: 1
  durationBetweenTurns: 1
  durationForCrossingReset: 2
  
  # units
  humanID: 'Hero Placeholder'
  ogreID: 'Hero Placeholder 1'
  thangTemplates:  # Biggest first
    humans: [
      {type: 'librarian-champion', goldCost: 64}
      {type: 'librarian', goldCost: 16}
      {type: 'sniper', goldCost: 4}
      {type: 'archer', goldCost: 1}
    ]
    ogres: [
      {type: 'shaman-champion', goldCost: 64}
      {type: 'shaman', goldCost: 16}
      {type: 'assassin', goldCost: 4}
      {type: 'thrower', goldCost: 1}
    ]
  treasureChestIDs:
    humans: 'Human Treasure Chest'
    ogres: 'Ogre Treasure Chest'
  gemIDs:
    humans: 'Gem 2'
    ogres: 'Gem'
  gemTemplates:
    humans: 'human-gem'
    ogres: 'ogre-gem'
  
  teamColors: 
    humans: '#ff0000'
    ogres: '#0000ff'
    
  chooseAction: ->
    @gameLoop()
  
  gameLoop: ->
    return if @turnState is @ALL_DONE_STATE
    
    # INITIALIZATION
    unless @map
      @initRound()

    # FINISH ROUND
    @teamWinningRound = @roundOver()
    if @teamWinningRound
      if not (@teamWinningRound in ['humans', 'ogres'])
        @finishRound()
        return
        
      if @turnState is @CROSSING_STATE
        return unless @crossingIsOver()
        @resetCrossing()
        @turnState = null
        @finishRound()
        @wait @durationForCrossingReset
      else
        @turnState = @CROSSING_STATE
        @beginCrossing()
      return

    # ASKING STATE
    unless @turnState
      @say "Bid for tile group " + @currentTileGroup + ".", this
      @showAvailableTileGroup()
      @turnState = @ASKING_STATE
      @askingSince = @world.age
      return

    # HANDLE BIDS
    if @turnState is @ASKING_STATE
      biddingOver = @humansBid and @ogresBid or (@world.age - @askingSince > @turnTime + @world.dt)
      if biddingOver
        @handleSubmissions()
        @turnState = @WATCHING_STATE
        @askingSince = null
        @assignTiles()
        @recordTurn()
        @wait @durationForWatching
        return

    # END TURN
    if @turnState is @WATCHING_STATE
      @goToNextTurn()
      @turnState = @humansBid = @ogresBid = null
      @wait @durationBetweenTurns
      return

  # INITIALIZATION #############################################################
  initRound: ->
    @human = @world.getThangByID @humanID
    @ogre = @world.getThangByID @ogreID
    console.log(@, @human, @ogre)
    if @round > 0
      @durationBetweenTurns = @world.dt
      @durationForWatching = @world.dt
      for hearer in [@, @human, @ogre]
        hearer.hearingDelay = hearer.hearingDelayMinimum = hearer.hearingDelayMaximum = 2 * @world.dt
    # turnTime is no longer deterministic given that the combat time can slightly vary
    @turnTime = @hearingDelayMaximum + Math.max(@human.hearingDelayMaximum, @ogre.hearingDelayMaximum) + @durationBetweenTurns + @durationForWatching
    @turn = @turnsSinceChange = 0
    @turns = []
    @human.setTurns @turns
    @ogre.setTurns @turns
    @currentTileGroup = @tileGroupLetters[@turn]
    @inventorySystem = @world.getSystem("Inventory")
    @inventorySystem.reset()
    @initMapAndTileGroups()
    @initControllableUnits()
    @initTiles()

  initMapAndTileGroups: ->
    # create an array of available tile group assignments, shuffle them
    tileGroupNumbers = []
    numNodes = @HEIGHT * @WIDTH
    for i in [0 ... numNodes]
      tileGroupNumber = Math.floor(i / @TILE_GROUP_SIZE)
      tileGroupNumbers.splice @world.rand.rand2(0, tileGroupNumbers.length), 0, tileGroupNumber

    # create the map of position to node object,
    # and a lookup array for which node is in which tileGroupNumber
    map = {}
    @tileGroups = {}
    for i in _.range(@WIDTH)
      for j in _.range(@HEIGHT)
        node = { owner: null, x: i, y: j, id: p(i,j), apiProperties: ['owner', 'id', 'x', 'y', 'tileGroupLetter', 'neighbors'] }
        tileGroupNumber = tileGroupNumbers.pop()
        node.tileGroupLetter = @tileGroupLetters[tileGroupNumber]
        @tileGroups[node.tileGroupLetter] ?= []
        @tileGroups[node.tileGroupLetter].push node
        map[p(i,j)] = node
        tile = @getThangForNodeID node.id
        tile.drawsBoundsIndex = tileGroupNumber

    @map = map
    
    # set up neighbor references
    for i in _.range(@WIDTH)
      for j in _.range(@HEIGHT)
        d = []
        d.push(p(i,j+1)) if j < @HEIGHT - 1
        d.push(p(i+1, j+1)) if j < @HEIGHT - 1 and i < @WIDTH - 1
        d.push(p(i+1, j)) if i < @WIDTH - 1
        d.push(p(i+1, j-1)) if j > 0 and i < @WIDTH - 1
        d.push(p(i, j-1)) if j > 0
        d.push(p(i-1, j-1)) if j > 0 and i > 0
        d.push(p(i-1, j)) if i > 0
        d.push(p(i-1, j+1)) if j < @HEIGHT - 1 and i > 0
        map[p(i,j)].neighbors = (@map[nodeID] for nodeID in d)

  initControllableUnits: ->
    @players = [@human, @ogre]
    @captainStartingPositions ?= {}
    @captainStartingScales ?= humans: @human.scaleFactor, ogres: @ogre.scaleFactor
    for player in @players
      player.setMap @map
      player.setTileGroups @tileGroups
      player.setRound @round
      player.updateAPIs()
      gem = @world.getThangByID @gemIDs[player.team]
      gem.setExists true
      @captainStartingPositions[player.team] ?= player.pos.copy()
      player.setAction 'idle'
      player.rotation = Vector.subtract(gem.pos, player.pos).heading()
      player.scaleFactor = @captainStartingScales[player.team]
      player.alpha = 1

  initTiles: ->
    unless @tileThangs
      @tileThangs = @getByType("tile")
      for tile in @tileThangs
        unless tile.actions["flip-human"]
          tile.addActions {name: "flip-human", cooldown: 0}, {name: "flip-ogre", cooldown: 0}, {name: "die", cooldown: 0}
    for tile in @tileThangs
      tile.setAction "idle"
      tile.alpha = 0.99
      tile.keepTrackedProperty 'alpha'
      
  # ASKING PHASE ###############################################################
  showAvailableTileGroup: ->
    #fadeOut = name: 'fade-out', targetProperty: 'alpha', setTo: 0.9, duration: @turnTime - 2 * @world.dt, reverts: true
    for node in @tileGroups[@currentTileGroup]
      nodeThang = @getThangForNodeID(node.id)
      if node.owner then continue
      if not nodeThang then continue
      #args = [parseFloat(nodeThang.pos.x),parseFloat(nodeThang.pos.y),1,'#BA55D3']
      #@addCurrentEvent "aoe-#{JSON.stringify(args)}"
      nodeThang.alpha = 1  # Shows the bounds rectangle overlay to highlight the tile
    for letter, otherTileGroup of @tileGroups when letter isnt @currentTileGroup
      for node in otherTileGroup
        tile = @getThangForNodeID node.id
        tile.alpha = 0.99
        #tile.addEffect fadeOut

  # HEARING PHASE ##############################################################
  handleSubmissions: ->
    @humansBid ?= team: 'humans'
    @ogresBid ?= team: 'ogres'
    @winningSubmission = @chooseWinnerFromSubmissions [@humansBid, @ogresBid]
    @winningSubmission.won = true if @winningSubmission
    #this.debug('Referee got bids: humans ' + @humansBid.bid + ', ogres ' + @ogresBid.bid);
    
  chooseWinnerFromSubmissions: (submissions) ->
    # each submission object has 
    #   bid (integer)
    #   team (string)
    #   desiredTile (string)
    
    for s in submissions
      funds = @inventorySystem.goldForTeam(s.team)
      #console.log "Got bid #{s.bid}, funds #{funds} for #{s.team} from inventory #{!!@inventorySystem}"
      s.invalidBid = false
      s.invalidBid = true unless _.isNumber s.bid
      s.invalidBid = true if s.bid > funds
      s.invalidBid = true unless s.bid > 0
      s.invalidBid = true unless s.bid % 1 is 0
      s.invalidTile = not Boolean(@getValidTileForSubmission(s))

    submissions = (s for s in submissions when not (s.invalidBid or s.invalidTile))
    return null unless submissions.length
    submissions = _.sortBy submissions, 'bid'
    
    @tieBreaker ?= @world.rand.randf() < 0.5
    if submissions.length is 2 and submissions[0].bid is submissions[1].bid
      submissions.reverse() if @tieBreaker
      @tieBreaker = not @tieBreaker
    return _.last submissions
    
  getValidTileForSubmission: (submission) ->
    return unless _.isString submission.desiredTile?.id
    return unless desiredTile = @map[submission.desiredTile.id]
    return unless desiredTile.tileGroupLetter is @currentTileGroup
    return if desiredTile.owner
    desiredTile
    
  awardWinningSubmission: (submission) ->
    @inventorySystem.subtractGoldForTeam(submission.team, submission.bid)
    chest = @world.getThangByID @treasureChestIDs[submission.team]
    unless chest.actions["open-full"]
      chest.addActions {name: "open-full", cooldown: 0}, {name: "open-empty", cooldown: 0}
    chest.setAction 'open-full'
    chest.act()
    chest.showText "-#{submission.bid}", color: '#FFD700'

    desiredTile = @getValidTileForSubmission submission
    @setOwner(desiredTile.x, desiredTile.y, submission.team) if desiredTile
    return desiredTile
    
  setOwner: (x, y, team) ->
    @map[p(x,y)].owner = team
    @map[p(x,y)].turnWon = @turn
    
  assignTiles: ->
    tile.alpha = 0.99 for tile in @tileThangs
    winningSubmission = @winningSubmission
    unless winningSubmission and node = @awardWinningSubmission winningSubmission
      @turnsSinceChange++
      @say "No valid bids.", null
      return
    @turnsSinceChange = 0

    message = winningSubmission.desiredTile.id + " to " + winningSubmission.team + " for " + winningSubmission.bid + "."
    @say message, null
    tileID = "Tile " + node.id
    tile = @world.getThangByID(tileID)
    if node.owner is "humans"
      # Make the tile appear to be won by humans
      tile.setAction "flip-human"
      tile.act()
    else if node.owner is "ogres"
      # Make the tile appear to be won by ogres
      tile.setAction "flip-ogre"
      tile.act()
    else
      @debug "Huh, we just awarded a node to", node.owner
      
  recordTurn: ->
    return unless _.string
    turn = {
      number: @turn
      tileGroup: @currentTileGroup
      humanGold: @inventorySystem.goldForTeam('humans')
      ogreGold: @inventorySystem.goldForTeam('ogres')
      humanBid: @humansBid
      ogreBid: @ogresBid
    }
    @turns.push turn

  # TURN OVER ##################################################################
  goToNextTurn: ->
    @winningSubmission = null
    @turn += 1
    @currentTileGroup = @tileGroupLetters[(@tileGroupLetters.indexOf(@currentTileGroup) + 1) % @tileGroupLetters.length]
    for player in @players
      player.updateAPIs()
    @world.getThangByID(@treasureChestIDs.humans).setAction 'idle'
    @world.getThangByID(@treasureChestIDs.ogres).setAction 'idle'
    
  # CROSSING ###################################################################
  
  beginCrossing: ->
    for captain in [@human, @ogre]
      continue if captain.erroredOut
      gem = @world.getThangByID @gemIDs[captain.team]
      captain.setAction 'move'
      path = @pathAcross captain.team
      winning = path
      unless path
        path = []
        for tp in [[0,3], [1,4], [2,3], [3,2], [4,3], [5,4], [6,3]]
          tp.reverse() if captain.team is 'ogres'
          tile = @map[p(tp[0], tp[1])]
          path.push tile
          break if tile.owner isnt captain.team
      waypoints = (@getThangForNodeID(tile.id).pos for tile in path)
      if winning
        if captain is @human
          waypoints.unshift {x:7, y:waypoints[0].y, z:0}
          waypoints.push {x:70, y:waypoints[waypoints.length-1].y, z:0}
        else
          waypoints.unshift {x: waypoints[0].x, y:12, z:0}
          waypoints.push {x:waypoints[waypoints.length-1].x, y:68, z:0}
        
      waypoints.push gem.pos
      captain.setWaypoints waypoints
      
    for tileID, tile of @map
      continue if tile.owner is @teamWinningRound
      tileThang = @getThangForNodeID tileID
      fadeDuration = 0.5
      fadeOut = name: 'fade-out', targetProperty: 'alpha', repeatsEvery: @world.dt, addend: -1 * @world.dt / fadeDuration, duration: fadeDuration
      tileThang.addEffect fadeOut
    
  crossingIsOver: ->
    for captain in [@human, @ogre]
      if captain.finishedWaypoints and captain.team isnt @teamWinningRound
        fallDuration = 1
        fall = name: 'fall', targetProperty: 'scaleFactor', repeatsEvery: @world.dt, addend: -captain.scaleFactor * fallDuration * @world.dt, duration: fallDuration, reverts: false
        fallHide = name: 'fall-hide', targetProperty: 'alpha', repeatsEvery: @world.dt, addend: -1 * fallDuration / 2 * @world.dt, duration: fallDuration * 2, reverts: false
        captain.addEffect fall
        captain.addEffect fallHide
        captain.addCurrentEvent 'fall'
        captain.maxAcceleration = 0  # Can't move while falling
        captain.finishedWaypoints = false
        captain.velocity.limit 10
      else
        gem = @world.getThangByID @gemIDs[captain.team]
        return true unless gem.exists
    false
    
  resetCrossing: ->
    for captain in [@human, @ogre]
      if captain.alpha > 0
        captain.addCurrentEvent 'leap'
      captain.setExists true
      start = @captainStartingPositions[captain.team]
      captain.velocity = Vector.subtract(start, captain.pos)
      captain.velocity.z = 30
      captain.setTargetPos start
      captain.maxAcceleration = 100
      captain.rotation = Vector.subtract(start, captain.pos).heading()
      captain.finishedWaypoints = false  # Make sure not to reset targetPos to null
    for thang in @world.thangs.slice() when thang.exists and thang.health?
      thang.setExists false

  # ROUND OVER #################################################################

  roundOver: ->
    return true if @turn > @MAX_TURNS
    return true if @turnsSinceChange >= 7
    return 'humans' if @pathAcross 'humans'
    return 'ogres' if @pathAcross 'ogres'
    
  pathAcross: (team) ->
    direction = {humans: 'horizontal', ogres: 'vertical'}[team]
    if direction is 'vertical'
      starterNodes = (p(i, 0) for i in _.range(@WIDTH))
    else
      starterNodes = (p(0, i) for i in _.range(@HEIGHT))
  
    open = []
    closed = {}
    for nodeKey in starterNodes
      open.push(nodeKey) if @map[nodeKey].owner is team
      closed[nodeKey] = true
  
    while open.length
      nodeKey = open.pop()
      node = @map[nodeKey]
      hasNeighbors = false
      for neighbor in node.neighbors
        if neighbor.owner is team
          if (direction is 'vertical' and neighbor.y is @HEIGHT - 1) or (direction is 'horizontal' and neighbor.x is @WIDTH - 1)
            path = [neighbor]
            closed[neighbor.id] = nodeKey
            while true
              currentNode = path[0]
              previousNode = @map[closed[currentNode.id]]
              break unless previousNode
              path.unshift previousNode
            return path
          unless closed[neighbor.id]
            open.push neighbor.id
            hasNeighbors = true
            closed[neighbor.id] = nodeKey
    false
    
  finishRound: ->
    if @turns.length
      turns = @stringifyTurns()
      turns.unshift 'Turn | Group | H-Gold | O-Gold | H-Bid       | O-Bid'
      turns.unshift "ROUND #{@round}"
      @debug turns.join('\n')
      @turns = []

    if @teamWinningRound isnt true # some rounds end without a team winning
      score = ++@roundScores[@teamWinningRound]
      @toBuild = @buildables[@gemTemplates[@teamWinningRound]]
      scoreGem = @performBuild()
      chest = @world.getThangByID @treasureChestIDs[@teamWinningRound]
      offset = [-4 - (2*(score-1)), 0]
      #offset.reverse() if @teamWinningRound is 'ogres'
      scoreGem.pos = Vector.add chest.pos, {x: offset[0], y: offset[1]}
      scoreGem.hasMoved = true
    @teamWinningRound = null
    @map = null
    @turnState = @humansBid = @ogresBid = null
    if ++@round is @NUM_ROUNDS or @roundScores.humans >=3 or @roundScores.ogres >= 3
      @finishGame()

  stringifyTurns: ->
    turns = @turns[..]
    for turn, i in turns
      args = [
        turn.number,
        turn.tileGroup,
        turn.humanGold,
        turn.ogreGold,
        @submissionToString(turn.humanBid),
        @submissionToString(turn.ogreBid)
      ]
      turns[i] = _.string.sprintf('%4d |   %s   | %6d | %6d | %-11s | %-11s ', args...)
    turns

  submissionToString: (submission) ->
    return '     -' if submission.invalidBid and submission.invalidTile

    if submission.invalidBid
      bidString = '???'
    else
      bidString = _.string.sprintf '%-3d', submission.bid
      
    if submission.invalidTile
      tileString = '(?,?)'
    else
      tileString = _.string.sprintf '(%d,%d)', submission.desiredTile.x, submission.desiredTile.y
      
    if submission is @winningSubmission
      markString = '*'
    else
      markString = ' '
    
    _.string.sprintf '%s %s %s', bidString, tileString, markString


  # FINISH GAME ################################################################
  
  finishGame: ->
    @turnState = @ALL_DONE_STATE
    @wait 3
    winner = null
    if @roundScores.humans > @roundScores.ogres
      @say "Game over, humans win!"
      winner = 'humans'
    else if @roundScores.ogres > @roundScores.humans
      @say "Game over, ogres win!"
      winner = 'ogres'
    else
      @say "Game over, no one wins!"
      @setGoalState "horizontal-path", "failure"
      @setGoalState "vertical-path", "failure"
    if winner is "ogres"
      @setGoalState "vertical-path", "success"
      @setGoalState "horizontal-path", "failure"
    else if winner is "humans"
      @setGoalState "vertical-path", "failure"
      @setGoalState "horizontal-path", "success"
      
  # UTILITIES ##################################################################
    
  getThangForNodeID: (nodeID) -> @world.getThangByID("Tile " + nodeID)
  
      


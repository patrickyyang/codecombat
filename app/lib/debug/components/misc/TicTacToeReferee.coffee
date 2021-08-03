Component = require 'lib/world/component'

module.exports = class TicTacToeReferee extends Component
  @className: 'TicTacToeReferee'
  
  constructor: (config) ->
    super config
    @gridSize = 3
    @tileWidth = 9
    @tileHeight = 7.5
    @X = 31
    @Y = 44
    @board = {}
    @board.grid = []
    @board.moveCount = 0
    @board.hasEnded = false
    #console.log 'debug',@board
    @moveCount = 0
    @winningCombo = [
      [ 0, 1, 2 ],
      [ 3, 4, 5 ],
      [ 6, 7, 8 ],
      [ 0, 3, 6 ],
      [ 1, 4, 7 ],
      [ 2, 5, 8 ],
      [ 0, 4, 8 ],
      [ 2, 4, 6 ]
    ]
    @heuristicArray = [
      [     0,   -10,  -100, -10000 ],
      [    10,     0,     0,     0 ],
      [   100,     0,     0,     0 ],
      [  10000,     0,     0,     0 ]
    ]

  attach: (thang) ->
    super thang
   
  ###  
  initBoard: ->
    for i in [0 ... @gridSize-1]
      for j in [0 ... @gridSize-1]
        @addRect(@X + (i * @squareSize),@Y + (j * @squareSize), @squareSize , @squareSize)
        @board[i][j] = 0
  ###
  
  getPossibleMoves: -> console.log "calling original version of getPossibleMoves"
  minimax_alphaBeta: -> console.log "hacky fix for error"
  evaluateBoard: -> console.log "hacky fix for error"
  
  AI_minimax_alphaBeta: (board,player,depth,alpha,beta) ->
    
    #console.log 'calling AI minimax board=',board,'player=',player,'depth=',depth,'alpha=',alpha,'beta=',beta
    
    if depth is 0 or board.hasEnded is true
      #console.log 'returning at first condition'
      #console.log 'returning score=',@evalBoard(board,player),'board=',board,'player=',player,'depth=',depth,'alpha=',alpha,'beta=',beta
      return {Move: {i: -1,j: -1}, score: @evalBoard(board,player)}
      
    moves = @getMoves(board)
    
    p = {Move: {i: -1,j: -1}, score: -10000}
    
    for move in moves
      #console.log 'in foreach'
      
      copy = _.cloneDeep(board)
      #console.log 'board=',board,'copy=',copy
      copy = @applyMove(copy,move.x,move.y,player)
      #console.log 'move=',move,'copy after applyMove=',copy
      
      
      if copy is false
        continue
        
      #player = player == 'X' ? 'O' : 'X'
      if player is 'X'
        player = 'O'
      else
        player = 'X'
      
      p2 = @AI_minimax_alphaBeta(copy,player,depth-1,-beta,-alpha)
      p2.score *= -1;
      
      if(p2.score >= p.score) 
        p.Move.i = move.x
        p.Move.j = move.y
        p.score = p2.score
        #console.log 'return 1'
        #return p
      
      if(p2.score > alpha) 
        alpha = p2.score
        #p.Move.i = move.x
        #p.Move.j = move.y
        
      
      if(alpha >= beta)
        #console.log 'prunning here'
        break
        
      if player is 'X'
        player = 'O'
      else
        player = 'X'
        
    #console.log 'return 2'
    #console.log 'returning p=',p, 'for call board=',board,'player=',player,'depth=',depth,'alpha=',alpha,'beta=',beta
    return p
    #return alpha
  
  initBoard: ->
    for i in [0 ... @gridSize]
      @board.grid[i] = []
      for j in [0 ... @gridSize]
        @board.grid[i][j] = 0
    console.log 'init board=' , @board
    
  getMoves: (board) ->
    moves = []
    for i in [0 ... @gridSize]
      for j in [0 ... @gridSize]
        if board.grid[i][j] is 0
          moves.push({x: i,y: j})
    return moves
    
  evalBoard: (board, player) ->
    #console.log 'evaluating for',player,'board=',board
    #opponent = (player == 'X') ? 'O' : 'X'
    if player is 'X'
      opponent = 'O'
    else
      opponent = 'X'
    value = 0
    
    
    for i in [0 ... 8]
        players = 0
        others = 0
        for j in [0 ... 3]
            piece = board.grid[Math.floor(@winningCombo[i][j] / 3)][@winningCombo[i][j] % 3]
            if piece is player
                players++
            else if piece is opponent
                others++
        value += @heuristicArray[players][others]
    #console.log 'value=',value
    return value
        
  spawnThang: (x, y, type) ->
    if type is 'X'
      @toBuild = @buildables.X
    else
      @toBuild = @buildables.O
    thang = @performBuild()
    thang.pos.x = x
    thang.pos.y = y
    thang.hasMoved = true
        
  addX: (i,j) ->
    if i < 3 and j < 3 and @board.grid[i][j] is 0
      @board.grid[i][j] = 'X'
      @spawnThang(@X + j * @tileWidth,@Y - i * @tileHeight,'X')
      @board.moveCount++
      console.log 'added an X, board=' , @board
      check = @checkWinner(@board,i,j,'X')
      #console.log 'check=',check
      if check isnt 0
        @board.hasEnded = true
        if check is 1
          console.log 'OMG you won!'
          @setGoalState('goal','success')
        else
          console.log 'draw from move',i,j,'by X'
          @setGoalState('goal','success')
        @world.endWorld(false,2)
        console.log 'game over'
      
  addO: (i,j) ->
    if i < 3 and j < 3 and @board.grid[i][j] is 0
      @board.grid[i][j] = 'O'
      @spawnThang(@X + j * @tileWidth,@Y - i * @tileHeight,'O')
      @board.moveCount++
      console.log 'added an O, board=' , @board
      check = @checkWinner(@board,i,j,'O')
      if check isnt 0
        @board.hasEnded = true
        if check is 2
          #console.log 'OMG you won!'
          @setGoalState('goal','failure')
        else
          console.log 'draw from move',i,j,'by O'
          @setGoalState('goal','success')
        @world.endWorld(false,2)
        console.log 'game over'
        
  applyMove: (board,i,j,player) ->
    #console.log 'in applyMove,checking arguments', board,i,j,player
    if i < 3 and j < 3 and board.grid[i][j] is 0
      #console.log 'check1'
      board.grid[i][j] = player
      board.moveCount++
      if @checkWinner(board,i,j,player) isnt 0
        board.hasEnded = true
      return board
    else
      #console.log 'check2'
      return false
      
  checkWinner: (board, x ,y ,player) ->
    #returns 0 for unfinished
    #        1 for X win
    #        2 for O win
    #        3 for draw
    
    #check for col
    for i in [0 ... @gridSize]
      if board.grid[x][i] isnt player
        #console.log 'x=',x,'i=',x,'break'
        break
      if i is @gridSize-1
        #console.log 'i=',i
        #console.log player,'wins on col'
        #return player == 'X' ? 1 : 2
        return {X: 1, O: 2}[player]
        
    #check for row
    for i in [0 ... @gridSize]
      if board.grid[i][y] isnt player
        break
      if i is @gridSize-1
        #console.log player,'wins on row'
        #return player == 'X' ? 1 : 2
        return {X: 1, O: 2}[player]
        
    #check diag
    if x is y
      for i in [0 ... @gridSize]
        if board.grid[i][i] isnt player
          break
        if i is @gridSize-1
          #console.log player,'wins on diag'
          #return player == 'X' ? 1 : 2
          return {X: 1, O: 2}[player]
          
    #check other diag
    for i in [0 ... @gridSize]
      if board.grid[i][@gridSize-1-i] isnt player
        break
      if i is @gridSize-1
        #console.log player,'wins on other diag'
        #return player == 'X' ? 1 : 2
        return {X: 1, O: 2}[player]
        
    #check draw
    if board.moveCount is 9
      #console.log 'DRAW'
      return 3
    
    #console.log 'unfinished'
    return 0
      
    
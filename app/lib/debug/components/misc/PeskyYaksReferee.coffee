Component = require 'lib/world/component'

module.exports = class PeskyYaksReferee extends Component
  @className: 'PeskyYaksReferee'
  
  beginPath: (_x, _y) ->
    @stack.push x: _x, y: _y
    @removeItem()
    @stack.pop()
    @stack.push x: _x + 1, y: _y
    @removeItem()
    @progressStack()
    
  progressStack: ->
    potential = []
    xVal = @stack[@stack.length - 1].x
    yVal = @stack[@stack.length - 1].y
    index = yVal * @xWidth + xVal
    if xVal - 2 >= 0 and @mineArray[index - 2] isnt 0
      potential.push [
        {x: xVal - 2, y: yVal},
        {x: xVal - 1, y: yVal}
      ]
    if xVal + 2 < @xWidth and @mineArray[index + 2] isnt 0
      potential.push [
        {x: xVal + 2, y: yVal},
        {x: xVal + 1, y: yVal}
      ]
    else if xVal + 2 is @xWidth
      if @potentialExits.indexOf({x: xVal + 1, y: yVal}) is -1
        @potentialExits.push({x: xVal + 1, y: yVal})
      else
        console.log(":((")
    if yVal - 2 > 0 and @mineArray[index - @xWidth * 2] isnt 0
      potential.push [
        {x: xVal, y: yVal - 2},
        {x: xVal, y: yVal - 1}
      ]
    if yVal + 2 < (@yHeight - 1) and @mineArray[index + @xWidth * 2] isnt 0
      potential.push [
        {x: xVal, y: yVal + 2},
        {x: xVal, y: yVal + 1}
      ]
    
    if potential.length isnt 0
      selectedIndex = Math.floor(Math.random() * potential.length)
      
      @stack.push potential[selectedIndex][0]
      @removeItem()
      
      @stack.push potential[selectedIndex][1]
      @removeItem()
      @stack.pop()
      @progressStack()
      potential = []
    else
      if @stack.length > 1
        @stack.pop()
        @progressStack()
      else
        @exitLocale = @potentialExits[Math.floor(Math.random() * @potentialExits.length)]
        @stack.push @exitLocale
        @removeItem()
    
  removeItem: ->
    xVal = @stack[@stack.length - 1].x
    yVal = @stack[@stack.length - 1].y
    @mineArray[yVal * @xWidth + xVal] = 0
    
  setUpLevel: ->
    @world.seed = Math.random()
    
    @exitLocale = null
    @potentialExits = []
    @stack = []
    @mineArray = []
    @xWidth = 15
    @yHeight = 18
    for i in [0 ... @xWidth]
      for j in [0 ... @yHeight]
        @mineArray.push 1
    @beginPath 0, (1 + Math.floor((@yHeight - 2) * Math.random()))
        
    #Draw the mines.    
    for i in [0 ... @mineArray.length]
      if @mineArray[i] is 1
        @instabuild "fire-trap", 16 + 4 * (i % 15), 68 - 4 * (i - (i % 15)) / 15
        
    @instabuild "x-marker", 16 + 4 * @exitLocale.x, 68 - 4 * @exitLocale.y
    
    @isSetup = true
        
  chooseAction: ->
    @setUpLevel() unless @isSetup
      
    
    
  
Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class QuickSortReferee extends Component
  @className: "QuickSortReferee"

  constructor: (config) ->
    super config
    @swapMoveThreshold = 2.0
    @swapTimeThreshold = 0.25
    @compareTimeThreshold = 0.5
    @executedSwaps = 0
    @executedCompares = 0

  attach: (thang) ->
    super thang
    thang.addActions? name: 'swap', cooldown: 1
    thang.addActions? name: 'compare', cooldown: 0
    
  isBigger: (item1,item2) ->
    if @comparing
      if(@comparingDoneSince and @world.age - @comparingDoneSince >= @compareTimeThreshold)
        @comparing = false
        @comparingDoneSince = null
        return "done"
      unless item1.isGrounded()
        item1.setAction 'idle'
        item2.setAction 'idle'
      if @comparingDoneSince
        return "compare" 
      else
        @comparingDoneSince = @world.age
      return "compare"
    @setAction "compare"
    @comparing = true
    
    item1.velocity.z = 10
    item1.pos.z += 5
    if item1 isnt item2
      item2.velocity.z = 10
      item2.pos.z += 5
    @executedCompares++
    
    if item1.scaleFactor and item2.scaleFactor
      return item1.scaleFactor > item2.scaleFactor
    else
      return false
      
  isSmaller: (item1,item2) ->
    
    if @comparing
      if(@comparingDoneSince and @world.age - @comparingDoneSince >= @compareTimeThreshold)
        @comparing = false
        @comparingDoneSince = null
        return "done"
      unless item1.isGrounded()
        item1.setAction 'idle'
        item2.setAction 'idle'
      if @comparingDoneSince
        return "compare"
      else
        @comparingDoneSince = @world.age
      return "compare"
    @setAction "compare"
    @comparing = true
    
    item1.velocity.z = 10
    item1.pos.z += 5
    if item1 isnt item2
      item2.velocity.z = 10
      item2.pos.z += 5
    @executedCompares++
    
    if item1.scaleFactor and item2.scaleFactor
      return item1.scaleFactor < item2.scaleFactor
    else
      return false
      
  swapItems: (array, firstElement, secondElement) ->
    #console.log 'array size=' , array.length , 'firstElement=' , firstElement , 'secondElement=' , secondElement , 'last scaleFactor=' , array[34].scaleFactor
    if @instantSwap
      @instantSwap = false
      return "done"
    if @swapping
      if (@swappingDoneSince and @world.age - @swappingDoneSince >= @swapTimeThreshold) or @getFriends().length > array.length
        @swapping = false
        @swappingDoneSince = null
        @swapElement1.setAction 'idle'
        @swapElement2.setAction 'idle'
        @swapElement1.targetPos = null
        @swapElement2.targetPos = null
        return "done"
      if @swappingDoneSince
        return "swap"
      #console.log @swapElement1, @swapElement1.distance?, @swapElement2, @swapElement2.distance
      if @swapElement1.distance(@swapTargetPos1) < @swapMoveThreshold and @swapElement2.distance(@swapTargetPos2) < @swapMoveThreshold
        @swappingDoneSince = @world.age
      unless @swapElement1.isGrounded()
        @swapElement1.setAction 'move'
        @swapElement2.setAction 'move'
        @swapElement1.jumpHeight = 10
        @swapElement1.updateJumpTime()
      return "swap"
    @swapElement1 = array[firstElement]
    @swapElement2 = array[secondElement]
    array[firstElement] = @swapElement2
    array[secondElement] = @swapElement1

    @executedSwaps++
    #console.log 'executed swaps = ' ,@executedSwaps
    #random comment
    if (array.length >10)
      if @checkSorted(array)
        #console.log 'array is sorted'
        @setGoalState("stage2", "success")

    if firstElement isnt secondElement
      @setAction 'swap'
      @swapping = true
      @swapTargetPos1 = @swapElement2.pos.copy()
      @swapTargetPos2 = @swapElement1.pos.copy()
      @swapElement1.jumpHeight = 20
      @swapElement1.updateJumpTime()
      @swapElement1.jumpTo @swapTargetPos1
      @swapElement2.jumpTo @swapTargetPos2
    else
      @instantSwap= true
    
    delete array.__aetherAPIClone
    return array
    
  shuffle = (a) -> # Fisher-Yates shuffle
    for i in [a.length-1..1]
      j = Math.floor @world.rand.randf() * (i + 1)
      [a[i], a[j]] = [a[j], a[i]]
    #a
    
  checkSorted: (array) ->
    #console.log 'checking if sorted ' 
    for i in [0 ... array.length - 1]
      #console.log array[i].scaleFactor
      if (array[i].scaleFactor > array[i+1].scaleFactor)
        #console.log 'not sorted because ' , array[i].scaleFactor , '>' , array[i+1].scaleFactor , 'i=',i
        return false
    #console.log 'is sorted'
    return true
    
  generateSpiral: ->
    
    friends = @getFriends()
    #console.log 'testing friends=' , friends
    for friend in friends
      friend.setExists(false)
      
    scaleList = []  
    for i in [0 ... 35]
      scaleList.push (0.5 + 1/35 * i )
    #console.log 'scaleList=' , scaleList
    
    shuffle(scaleList)
    #console.log 'shuffled scaleList=', scaleList
    
    centerx = 15
    centery = 40

    a = 5
    b = 30

    lastPos = new Vector centerx, centery
    for i in [0 ... 720]
      angle = i * Math.PI / 180
      x = centerx + (a + b * i / 720) * Math.cos(angle)
      y = centery + (a + b * i / 720) * Math.sin(angle)
      thisPos = new Vector x, y
      if thisPos.distance(lastPos) > 7 * (0.5 + i / 720)
        @toBuild = @buildables.ogre
        thang = @performBuild()
        thang.pos.x = x
        thang.pos.y = y
        thang.scaleFactor = scaleList.pop()
        thang.keepTrackedProperty 'scaleFactor'
        thang.hasMoved = true
        lastPos = thisPos
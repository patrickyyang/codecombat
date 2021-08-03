Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'
Vector = require 'lib/world/vector'

module.exports = class ExplosiveRings extends Component
  @className: 'ExplosiveRings'

  attach: (thang) ->
    explosiveRingAction = name: 'explosiveRing', cooldown: @cooldown, specificCooldown: @specificCooldown
    delete @cooldown
    delete @specificCooldown
    super thang
    thang.addActions explosiveRingAction

  
  canExplosiveRing: ->
    return false unless @canAct('explosiveRing')

  explosiveRing: (distance=10) ->
      @intent = 'explosiveRing'
      return @block?() unless @commander

  performExplosiveRing: ->
    console.log('Explosive Ring Attempt')
    #return unless @canExplosiveRing()
    console.log('Explosive Ring Attempt, got past guardians')

    @announceAction? 'explosiveRing'

    #blinkVector = Vector.subtract(@getTargetPos(), @pos).limit(@blinkRange)
    distance = 12
    D = distance
    #path = new Vector(distance,0)
    #target = Vector.add(path, @pos)

    @unblock?()
    @intent = undefined
    @unhide?() if @hidden

    i=0
    c = 1
    while c<4
      bombs = 12*c
      i=0
      while i<bombs
        path = new Vector(distance,0)
        path = path.rotate(2*i*Math.PI/bombs)
        #path = path.multiply(2)
        target = Vector.add(path, @pos)
  
        @setTargetPos target, 'throw'
        @configureThrownMissile() unless @thrownMissileComponents
        return unless @thrownMissileComponents
        @lastMissileThrown = @spawn @thrownMissileSpriteName, @thrownMissileComponents
        @lastMissileThrown.launch? @, 'throw'
        i+=1
        path = path.rotate(Math.PI/6)
        path = path.multiply(1.1)
        target = Vector.add(path, @pos)
      distance += D
      c+=1

      
    @brake?()
    #@sayWithoutBlocking? "Ring of Fire!"
    
    
    @lastMissileThrown
    
  update: ->
    console.log('updating explosiveRing')
    return unless @intent is 'explosiveRing' and @isGrounded()
    console.log('intent is good')
    if @action isnt 'explosiveRing'
      @setAction 'explosiveRing'
    console.log(@action)
    #return unless @action is 'explosiveRing' and @act()
    console.log('here we go!')
    @performExplosiveRing()
    @unblock()
    @intent = undefined
    @setTarget null
    @setAction 'idle'




Component = require 'lib/world/component'

{ArgumentError} = require 'lib/world/errors'
Vector = require 'lib/world/vector'


module.exports = class ChainLightning extends Component
  @className: 'ChainLightning'
  
  constructor: (config) ->
    super config
    @_chainLightningSpell = 
      name: 'chain-lightning',                  #x#spell name
      cooldown: @cooldown,                      #x#the cooldown
      specificCooldown: @specificCooldown,      #x#specific cooldown
      range: @range,                            #x#how far this spell can be cast
      damage: @damage,                          #x#how much damage the spell does
      bounceCount: @bounceCount,                #x#how many this spell bounces
      damageMultiplier: @damageMultiplier,      #x#what fraction of damage continues through the bounces
      bounceRange: @bounceRange,                #x#how far the spell can bounce
      forks: @forks,                            #o#whether or not this spell forks (INCOMPLETE)
      forkCount: @forkCount,                    #o#how many times this spell forks (INCOMPLETE)
      chainReturnMinimum: @chainReturnMinimum,  #x#how many bounces before this spell can chain back to an already afflicted enemy.
      chainBirthTime: @chainBirthTime,          #x#how long before the chain propogates
      chainLifeTime: @chainLifeTime,            #x#how long the chain exists in world
      chainRandomnessBias: @chainRandomnessBias #x#the likely hood that a chain will pick the nearest enemy, or any other within range.
    delete @cooldown
    delete @specificCooldown
    delete @range
    delete @damage
    delete @bounceCount
    delete @damageMultiplier
    delete @bounceRange
    delete @forks
    delete @forkCount
    delete @chainReturnMinimum
    delete @chainBirthTime
    delete @chainLifeTime
    delete @chainRandomnessBias
    
  attach: (thang) ->
    @chainLightningThangType = (@requiredThangTypes ? [])[0]
    thang.requiredThangTypes = (thang.requiredThangTypes ? []).concat(@requiredThangTypes ? [])
    thang.componentsForThangType @chainLightningThangType if @chainLightningThangType  # Make sure the Components are saved to the world's classMap.
    delete @requiredThangTypes
    super thang
    thang.addSpell @_chainLightningSpell
  
  'perform_chain-lightning': ->
    @unhide?() if @hidden
    @configureChainLightningMissile() unless @chainLightningComponents
    
    #Preload the targets hit with this, so we can back reference...
    @targetsHit = [@]
    @chainBolts = []
    for a in [0 ... (@spells['chain-lightning'].bounceCount + 1)]
      return unless @target and @target isnt null
      @targetsHit.push(@target)
        
      curTarget = @target
      @setTarget @findNextClosest()
      
      if not @chainLightningComponents
        throw new ArgumentError "There was a problem loading the Chain Lightning Thang Components."
      else
        #Spawning code below
        #Warning to all who enter.
        
        chainLightning = @spawn @chainLightningSpriteName, @chainLightningComponents
        chainLightning.setExists true
        
        #Track the properties that change, like pos, rot, etc.
        chainLightning.keepTrackedProperty 'pos'
        chainLightning.keepTrackedProperty 'rotation'
        chainLightning.keepTrackedProperty 'scaleFactorX'
        chainLightning.keepTrackedProperty 'scaleFactorY'
        
        #Parts of the custom-made update function
        #How long before being 'born' and doing damage
        chainLightning.birthspan = a * @spells['chain-lightning'].chainBirthTime
        chainLightning.isBorn = false
        #How long to exist in the world before dying
        chainLightning.lifespan = @spells['chain-lightning'].chainLifeTime
        chainLightning.maxLife = @spells['chain-lightning'].chainLifeTime
        
        chainLightning.damageIs = @spells['chain-lightning'].damage * Math.pow(@spells['chain-lightning'].damageMultiplier, a)
        #Start at 0 to 'appear' invisible
        chainLightning.scaleFactorY = 0
        chainLightning.update = ->
          @birthspan -= @world.dt
          if @birthspan <= 0 and not @isBorn
            #Once 'born' deal damage
            if @prevRef
              @oT = @prevRef.eT
            if @oT and @eT and (@eT.health <= 0 or @eT is @oT)
              potential = @spawner.getEnemies()
              index = potential.indexOf(@oT)
              if index isnt -1
                potential.splice(index, 1)
              @eT = @oT.findNearest(potential)
              if not @eT or @eT.distanceTo(@oT) > @tBounceRange
                @setExists false
            if @eT
              @eT.takeDamage @damageIs, @spawner
              @isBorn = true
            else
              @setExists false
              
          if @isBorn
            if @oT and @eT  # Trying to work around yet another error where something.pos is referenced with null something
              @pos = Vector.divide(Vector.add(@oT.pos, @eT.pos), 2)
              @diff = Vector.subtract(@oT.pos, @eT.pos)
              @rotation = @diff.heading()
              @hasRotated = true
              @scaleFactorX = Math.max 0.2, 1 / 10 * @diff.magnitude() / 2
            
            @lifespan -= @world.dt
            #Spike to 1 at birth, decrease down to 0 over lifespan
            @scaleFactorY = 2 * Math.max(@lifespan / @maxLife, 0)
            if @lifespan <= 0
              @setExists false
          return
        
        chainLightning.tBounceRange = @spells['chain-lightning'].bounceRange
        
        #References to the spawner, originater, and ending targets.
        
        chainLightning.spawner = @
        chainLightning.oT = @targetsHit[@targetsHit.length - 2] #origin Target
        chainLightning.eT = @targetsHit[@targetsHit.length - 1] #end Target
        
        #Position becomes between original target and end target ((A+B)/2)
        #This is because the rotation vector for Beam is in the middle, not on an end.
        chainLightning.pos = Vector.divide(Vector.add(chainLightning.oT.pos, chainLightning.eT.pos), 2)
        
        #Find the direction between OT and ET.
        chainLightning.diff = Vector.subtract(chainLightning.oT.pos, chainLightning.eT.pos)
        #Set rotation to the heading
        chainLightning.rotation = chainLightning.diff.heading()
        chainLightning.hasRotated = true
        
        #Beam length is ~10 long. Multiply it by the magnitude between the two points of OT and ET
        #Divide by 2 because it grows in both directions, since the origin is in the center
        chainLightning.scaleFactorX = Math.max 0.2, 1 / 10 * chainLightning.diff.magnitude() / 2
        
        if @chainBolts.length > 0
          chainLightning.prevRef = @chainBolts[@chainBolts.length - 1]
        
        @chainBolts.push chainLightning
        
    @brake?()
    return null

      
  findNextClosest: ->
    distTargets = []
    potentialTargets = @findEnemies()
    
    for target in potentialTargets
      distTargets.push([target, @target.distance(target)])
      
    distTargets.sort (a, b) ->
      if(a[1] < b[1])
        return -1
      else if (a[1] > b[1])
        return 1
      return 0
    
    
    potentialTargets = [];
    for target in distTargets
      if(@spells['chain-lightning'].chainReturnMinimum < 2)
        if target[0] isnt @target and @targetsHit.indexOf(target[0]) == -1
          if @target.distance(target[0]) > @spells['chain-lightning'].bounceRange
            break
          else
            potentialTargets.push(target[0])
      else
        if target[0] isnt @target
          if @targetsHit.indexOf(target[0]) == -1 or @targetsHit.indexOf(target[0]) <= ((@targetsHit.length - 1) - @spells['chain-lightning'].chainReturnMinimum)
            if @target.distance(target[0]) > @spells['chain-lightning'].bounceRange
              break
            else
              potentialTargets.push(target[0])
    
    if potentialTargets.length > 0
      return potentialTargets[Math.floor(potentialTargets.length * Math.random() * @spells['chain-lightning'].chainRandomnessBias)]
    else
      return null
    
    
  configureChainLightningMissile: ->
    if @chainLightningThangType
      @chainLightningComponents = _.cloneDeep @componentsForThangType @chainLightningThangType
      @chainLightningSpriteName = _.find(@world.thangTypes, original: @chainLightningThangType)?.name ? @chainLightningThangType
    if @chainLightningComponents?.length
      if allied = _.find(@chainLightningComponents, (c) -> c[1].team)
        allied[1].team = @team
    else
      console.log @id, "CastsChainLightning problem: couldn't find missile to shoot for type", @chainLightningThangType
    
    
    
System = require 'lib/world/system'

# Should be added after Events but before everything else so that thangs all update() after previous currentEvents were recorded but before the other systems happen
module.exports = class Existence extends System
  constructor: (world, config) ->
    super world, config
    @extant = @addRegistry (thang) -> thang.exists
    @world.lifespan = @lifespan
    @world.frameRate = @frameRate
    @world.dt = 1 / @world.frameRate
    # @world.totalFrames will be overwritten when world ends, whereas @world.maxTotalFrames doesn't change.
    @world.totalFrames = @world.maxTotalFrames = @lifespan * @world.frameRate
    @world.age = 0
    seed = switch @randomSeed
      when 'zero' then 0
      when 'playerCode' then @hashString @flattenUserCodeMap()
      when 'playerSession' then @hashString @flattenSessionIDs()
      when 'submissionCount' then @hashString(@flattenSessionIDs()) + (@world.submissionCount ? 0)
    if @world.fixedSeed
      seed = @world.fixedSeed
      console.log "Using fixed seed", seed
    else if @randomSeed in ["playerSession", "submissionCount"]
      console.log "Generated random seed", seed, "of type", @randomSeed, "from sessionIDs", @world.levelSessionIDs, "submissionCount", @world.submissionCount if @world.levelSessionIDs?.length is _.filter(@world.levelSessionIDs ? []).length
    else
      console.log "Generated random seed", seed, "of type", @randomSeed
    @world.randomSeed = seed
    @world.rand.setSeed? seed

  start: (thangs) ->
    thang.initialize?() for thang in thangs.slice()  # Might not be defined, but if it is, let's call it once.
    
  startTrackingDelayedThangs: ->
    # Only do this if we actually are using DelaysExistence, which we don't often use.
    return if @delayed
    @delayed = @addRegistry (thang) -> thang.appeared is false
    thang.updateRegistration() for thang in @world.thangs when thang.appeared is false

  update: ->
    thang.possiblyRevive() for thang in @delayed.slice() if @delayed  # @delayed might be modified during iteration
    thang.update?() for thang in @extant.slice()  # @extant might be modified during iteration
    return hash = 0
    
  flattenSessionIDs: ->
    ids = @world.levelSessionIDs ? ['no sessions']
    ids.sort()
    ids.join ''

  flattenUserCodeMap: ->
    code = []
    for thangID, methods of @world.userCodeMap
      for methodName, method of methods
        code.push method.raw if method.raw
        # This will not work for multiplayer when we send out only transpiled code; match outcomes will change.
    code.sort()
    code.join ''

  # djb2 algorithm
  hashString: (str) ->
    (str.charCodeAt i for i in [0...str.length]).reduce(((hash, char) -> ((hash << 5) + hash) + char), 5381)  # hash * 33 + c
    
  buildTypePower:
    "ogre-munchkin-m": 1.0
    "ogre-munchkin-f": 1.0
    "munchkin": 1.0
    
    "ogre-thrower": 3.7
    "thrower": 3.7
    
    "archer-m": 20.5
    "archer-f": 20.5
    "archer": 20.5
    
    "soldier-m": 30.3
    "soldier-f": 30.3
    "soldier": 30.3
    
    "ogre-scout-m": 32.1
    "ogre-scout-f": 32.1
    "scout": 32.1
    
    "decoy": 45.5
    
    "ogre-m": 49.8
    "ogre": 49.8
    
    "ogre-shaman": 58.0
    "shaman": 58.0
    
    "peasant-m": 75.0
    "peasant-f": 75.0
    "peasant": 75.0
    
    "ogre-peon-m": 75.0
    "ogre-peon-f": 75.0
    "peon": 75.0
    
    "skeleton": 153.4
    
    "ogre-f": 204.6
    
    "ogre-fangrider": 226.8
    "fangrider": 226.8
    
    "griffin-rider": 237.1
    
    "artillery": 386.2
    
    "paladin": 546.8
    
    "ogre-witch": 646.7
    "witch": 646.7
    
    "ogre-headhunter": 820.9
    "headhunter": 820.9
    
    "arrow-tower": 860.9
    
    "ogre-brawler": 878.6
    "brawler": 878.6
    
    "catapult": 977.9
    
    "burl": 982.3
    
    "robobomb": 1219.8
    
    "ogre-warlock": 1283.2
    "warlock": 1283.2
    
    "sand-yak": 1729.0
    
    "ogre-warlock": 2566.5
    "warlock": 2566.5
    
    "yeti": 3578.8
    
    "ogre-chieftain": 4518.1
    "chieftain": 4518.1
    
    "ice-yak": 7423.1
    
    "robot-walker": 9001
    "robot": 9001
    
    "thoktar": 9440.8

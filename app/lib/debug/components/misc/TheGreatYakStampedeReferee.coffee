Component = require 'lib/world/component'
Vector = require 'lib/world/vector'

module.exports = class TheGreatYakStampedeReferee extends Component
  @className: 'TheGreatYakStampedeReferee'
  chooseAction: ->
    if @firstRun
      @actors.thoktar.isAttackable = false
      @firstRun = false
    
    @checkVictory()
    @jibberJabber()
    if @fenceBuilt() and @world.age >= 16
      yaks = (t for t in @world.thangs when t.type is 'sand-yak' and t.exists)
      for yak in yaks
        yak.waypoints = [new Vector(49, 25)]
        yak.maxSpeed = 35
      if 21 < @world.age < 22
        @say "Wait! No!"
      if 23 < @world.age < 24
        @say "Yaks! Not that way!"
      else if @world.age > 28.5
        if @humbugged
          @move new Vector(75, 60)
        else
          @say "Bah!"
          @attackDamage = 9000
          @attackPos new Vector(49, 25)
          @humbugged = true
          # Now don't raise the dead.
          for spellName, heat of @spellHeats
            @spellHeats[spellName] = 9001
          # Seriously, stop it.
          @spells['raise-dead'].radius = 5
    
  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    
    @actors =
      "thoktar": @world.getThangByID 'Thoktar'
      "hector": @world.getThangByID 'Hector'
      "brom": @world.getThangByID 'Brom'
      "mary": @world.getThangByID 'Mary'
      "durfkor": @world.getThangByID 'Durfkor'
      "katelyn": @world.getThangByID 'Katelyn'
    
  jibberJabber: ->
    now = Math.round(@world.age)
    emotes = [
      {time: 4, actor: @actors.durfkor, message: "Hey Mary, these are some..."}
      {time: 7, actor: @actors.durfkor, message: "funny-looking stepping stones, eh?"}
      {time: 9, actor: @actors.mary, message: "Sure are, but kind of pretty..."}
      {time: 11, actor: @actors.mary, message: "with that flashing red light!"}
      {time: 13, actor: @actors.thoktar, message: "Bwahaha-haa!"}
      {time: 14, actor: @actors.hector, message: "What's that sound? Thunder?"}
      {time: 16, actor: @actors.mary, message: "Oh, you know your hearing..."}
      {time: 18, actor: @actors.mary, message: "...ain't what it used to be."}
    ]
    
    for emote in emotes
      if now is emote.time
        emote.actor.say emote.message
    
  checkVictory: ->
    if @actors.hector.health < 1 or @actors.brom.health < 1 or @actors.mary.health < 1 or @actors.durfkor.health < 1 or @actors.katelyn.health < 1
      @setGoalState 'save', 'failure'
    else if @world.age >= 30
      @setGoalState 'save', 'success'
    else if @fenceBuilt()
      @setGoalState 'fence', 'success'
  
  fenceBuilt: ->
    #
    # fenceBuilt
    #   | returns true if the player has built the fence in the correct place
    #
    built = false
    fences = (t for t in @world.thangs when t.spriteName is 'Fence Wall' and t.exists)
    for fence in fences
      if @rectangles['fence'].containsPoint fence.pos
        built = true
    built
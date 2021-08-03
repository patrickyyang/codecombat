Component = require 'lib/world/component'

module.exports = class HearsAndObeys extends Component
  @className: "HearsAndObeys"
  hear: (speaker, command, data) ->
    return if @health <= 0
    return if speaker.team isnt @team
    return if data?.type and data.type isnt @type
    #console.log @id, "hearing", speaker.id, "say", command
    (acknowledged = @acknowledgedSpeakerCommands ?= {})[speaker.id] ?= {}
    commandLower = command.toLowerCase()
    matchesCommand = (synonyms) -> return true for s in synonyms when commandLower.search(s) isnt -1
    target = data?.target
    targetPos = data?.targetPos
    @specificAttackTarget = null
    if @actions.move and matchesCommand ['move', 'go to']
      if targetPos and targetPos.x? and targetPos.y?
        try
          @move targetPos
        catch error
          #console.log "Ignoring move command with targetPos", targetPos, "due to error:", error.toString()
          @say? "What kind of targetPos is {x: #{targetPos.x}, y: #{targetPos.y}}?"
      else if target and target.pos and target.isThang
        @follow target
      else
        @say? "Where to?"
    else if @defend and matchesCommand ['defend']
      if targetPos and targetPos.x? and targetPos.y?
        try
          @defendPos targetPos
        catch error
          #console.log "Ignoring defend command with targetPos", targetPos, "due to error:", error.toString()
          @say? "What kind of targetPos is {x: #{targetPos.x}, y: #{targetPos.y}}?"
      else if target and target.isThang
        @defend target
      else
        @defend()
    else if @actions.move and matchesCommand ['follow', 'come with', "let's go"]
      @follow speaker
      acknowledged.follow = true  # could make them not re-follow if desired...
    else if @actions.move and @say and not acknowledged.follow and matchesCommand ["who goes there?"]
      @say? @id
      @follow speaker
      acknowledged.follow = true
      return
    else if @actions.attack and matchesCommand ['charge', 'attack', 'kill', 'fight', 'battle', 'slay', 'maul', 'destroy', 'exterminate', 'overwhelm', 'stab', 'assault', 'annihilate', 'assassinate', 'dispatch', 'eradicate', 'murder', 'massacre', 'obliterate', 'slaughter', 'wipe out', 'defeat', '杀']
      if target?.isAttackable
        @attack target
        @specificAttackTarget = target
      else if speaker.target?.isAttackable and (not @team or speaker.target.team isnt @team)
        @attack speaker.target
      else
        @attack @getNearestEnemy()
    else if matchesCommand ['hail', 'hello', 'hi!', 'hi ', 'greetings']
      if speaker.id is "Tharin"
        punct = ["!", "! ", "."][@world.rand.rand 3]  # accomodate multiple sound files
      else
        punct = "!"
      unless acknowledged.hail
        @say? "Ho, #{speaker.id}#{punct}"
      acknowledged.hail = true
      return
    else
      return  # No commands matched
    if @obeyResponses?.length
      i = @world.rand.rand @obeyResponses.length
      @say? @obeyResponses[i]

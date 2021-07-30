System = require 'lib/world/system'

module.exports = class Vision extends System
  constructor: (world, config) ->
    super world, config
    @flags = []

  update: ->
    hash = 0
    for flagEvent in (@world.flagHistory ? []) when not flagEvent.processed and flagEvent.time <= @world.age
      hash += @processFlagEvent flagEvent
    for flag in @flags when flag.active
      if @world.age > flag.appearedAt + 1
        flag.setAction 'idle'
    return hash
    
  processFlagEvent: (flagEvent) ->
    return if flagEvent.processed or flagEvent.time > @world.age
    flagEvent.processed = true
    flagID = flagEvent.color[0].toUpperCase() + flagEvent.color.slice(1) + ' ' + flagEvent.team[0].toUpperCase() + flagEvent.team.slice(1) + ' Flag'
    flag = @world.getThangByID(flagID) ? @createFlag(flagID, flagEvent.color, flagEvent.team)
    @updateFlag flag, flagEvent
    hash = (flag.pos.x - flag.pos.y) / flagEvent.color.length + flag.exists
    hash

  createFlag: (id, color, team) ->
    thangTypeName = 'Flag'  # Guaranteed loaded by the LevelLoader
    flag = new Thang @world, thangTypeName, id
    components = @makeFlagComponents(color, team)
    flag.addComponents components...
    flag.keepTrackedProperty 'exists'  # So that we don't pretend it always existed
    flag.addActions {name: 'appear', cooldown: 0}, {name: 'disappear', cooldown: 0}
    #flag.setAction 'appear'  # TODO: figure out how to 'appear' only when doing playback, not when placing the flag in real time
    flag.updateRegistration()
    @world.thangs.unshift flag
    @world.setThang flag
    flag.initialize?()
    @flags.push flag
    flag
    
  updateFlag: (flag, flagEvent) ->
    wasActive = flag.exists
    flag.setExists flagEvent.active  # TODO: figure out how to leave time for 'disappear' action animation
    flag.player = flagEvent.player
    if flagEvent.active
      flag.addTrackedProperties ['pos', 'Vector']
      flag.keepTrackedProperty 'pos'
      flag.pos.x = flagEvent.pos.x
      flag.pos.y = flagEvent.pos.y
      unless wasActive
        #flag.setAction 'appear'  # TODO: figure out how to 'appear' only when doing playback, not when placing the flag in real time
        flag.appearedAt = @world.age
    
  makeFlagComponents: (color, team) ->
    [
      ["Acts", {}]
      ["Exists", {}]
      ["Physical", {
        pos: {x: 10, y: 10, z: 4}
        width: 1
        height: 1
        depth: 8
        shape: "ellipsoid"
      }]
      ["Allied", {team: team}]
      ["HasAPI", {
        apiProperties: [
          "id"
          "pos"
          "team"
          "type"
          "color"
          "creationTime"
        ]
        apiMethods: [
          "findNearest"
          "distanceTo"
          "distance"
        ]
        type: 'flag'
        color: color
        creationTime: @world.age
      }]
      ["Selectable", {extraHUDProperties: ['color'], excludedHUDProperties: ['target', 'action'], inThangList: false}]
    ]

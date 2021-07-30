System = require 'lib/world/system'

module.exports = class Alliance extends System
  constructor: (world, config) ->
    super world, config
    @teamConfigs = @teams
    @teamConfigs ?= {"humans":{"superteam":"humans","color":{"hue":0,"saturation":0.75,"lightness":0.5},"playable":true},"ogres":{"superteam":"ogres","color":{"hue":0.66,"saturation":0.75,"lightness":0.5},"playable":false},"neutral":{"superteam":"neutral","color":{"hue":0.33,"saturation":0.75,"lightness":0.5}}}
    # For hacky performance, I also hardcoded these default colors in LevelLoader. We could just include them in only that one place...
    @playableTeams = (team for team, config of @teamConfigs when config.playable)
    @world.addTrackedProperties 'teamConfigs', 'playableTeams'
    @world.teamConfigs = @teamConfigs
    @world.playableTeams = @playableTeams
    @teams = {}
    @superteams = {}
    @allAlliedThangs = @addRegistry (thang) -> thang.exists and not thang.dead

  register: (thang) ->
    team = thang.team
    return unless team
    superteam = thang.superteam
    allies = @teams[team] ?= @addRegistry (thang) -> thang.team is team and thang.exists and not thang.dead
    allAllies = @superteams[superteam] ?= @addRegistry (thang) -> thang.superteam is superteam and thang.exists and not thang.dead
    super thang
    thang.allies = allies
    thang.allAllies = allAllies

  hasThangs: (team) ->
    @teams[team]?.length

  update: ->
    hash = 0
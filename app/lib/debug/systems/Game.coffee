System = require 'lib/world/system'

module.exports = class Game extends System
  constructor: (world, config) ->
    super world, config

  start: (thangs) ->
    gameThangs = (t for t in thangs when t.isGameReferee)
    unless gameThangs.length is 1
      console.log "Problem: Game System is active and needs one game.GameReferee Thang, but found", gameThangs.length, (t.id for t in gameThangs).join(', ')
    return unless @world.game = gameThangs[0]

  update: ->
    hash = 0
    return hash

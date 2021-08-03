Component = require 'lib/world/component'

module.exports = class KithgardBrawlReferee extends Component
  @className: 'KithgardBrawlReferee'

  chooseAction: ->
    @setUp() unless @didSetUp
    @spawnPotions()
    
  setUp: ->
    @didSetUp = true
    @hero = @world.getThangByID 'Hero Placeholder'
    

  spawnPotions: ->
    potion = @world.getThangByID 'Health Potion Large'
    return if potion
    return if @hero.health > @hero.maxHealth * 0.75
    return if Math.random() > 0.1
    pos = @pickPointFromRegions([@rectangles.middle])
    @instabuild 'health-potion-large', pos.x, pos.y    

  getRandom: (min,max) ->
    return Math.floor(Math.random() * (max - min + 1)) + min
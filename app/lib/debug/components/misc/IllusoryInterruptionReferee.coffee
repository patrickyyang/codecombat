Component = require 'lib/world/component'

module.exports = class IllusoryInterruptionReferee extends Component
  @className: 'IllusoryInterruptionReferee'
  chooseAction: ->
    hero = @world.getThangByID 'Hero Placeholder'
    trigger = @world.getThangByID 'Decoy Trigger'
    if hero.distanceTo(trigger) < 1 and !hero.activatedDecoy 
      decoy = @world.getThangByID 'Decoy'
      # modifies the direction the decoy moves
      decoy.spawnPos = trigger.pos
      decoy.inactive = false
      hero.activatedDecoy = true
    
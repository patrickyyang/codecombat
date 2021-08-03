Component = require 'lib/world/component'

module.exports = class PreferentialTreatmentReferee extends Component
  @className: 'PreferentialTreatmentReferee'
  chooseAction: ->
    @preferentialTreatmentSetUp() unless @didPreferentialTreatmentSetUp

  preferentialTreatmentSetUp: ->
    @didPreferentialTreatmentSetUp = true
    if @hero.maxHealth > 500
      n = (@hero.maxHealth - 500) / 50
      console.log('hero health is [' + @hero.maxHealth + '], spawn [' + n + '] extra mobs')
      for i in [0...n]
        p = @pickPointFromRegions([@rectangles.extraSpawnRegion])
        t = ['ogre-munchkin-f', 'ogre-munchkin-m'][@world.rand.rand(2)]
        @instabuild(t, p.x, p.y)

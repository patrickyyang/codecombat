Component = require 'lib/world/component'

module.exports = class MadMaxerReferee extends Component
  @className: 'MadMaxerReferee'

  setUpWaves: ->
    # scale wave power by hero health
    # 7 = Amara
    f = Math.max(1, @hero.maxHealth / 7)
    munchf = f * f * f
    rangef = f * f
    #console.log('hero [' + @hero.type + '] maxHealth [' + @hero.maxHealth + '] munchkin factor [' + munchf + '] ranger factor [' + rangef + ']')
    for wave in @waves
      if /escort$/.test(wave.name)
        wave.scaledPower *= munchf
      else if wave.scaledPower < 200
        wave.scaledPower *= rangef
      #console.log('wave [' + wave.name + '] power [' + wave.scaledPower + ']')

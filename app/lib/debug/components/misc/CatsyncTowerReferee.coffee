Component = require 'lib/world/component'

module.exports = class CatsyncTowerReferee extends Component
  @className: 'CatsyncTowerReferee'

  chooseAction: ->
    grif = @world.getThangByID 'Grif'
    grif.setTargetPos x: 8, y: 16
    grif.setAction 'move'
    grif.act()
    
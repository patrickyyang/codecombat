Component = require 'lib/world/component'

module.exports = class HoldTheForestPass extends Component
  @className: 'HoldTheForestPass'
  chooseAction: ->
    @doChatter()
    
  setUpLevel: ->
    @hero = @world.getThangByID 'Hero Placeholder'
    
  doChatter: ->
    now = Math.round(@world.age)
    if now is 2
      @hero.sayWithoutBlocking "Ogres! To Arms!"
    if now is 7
      @hero.sayWithoutBlocking "More incoming!"
    if now is 19
      @hero.sayWithoutBlocking "One more wave! Hold them off!"
      
# Just playing with scripting a bit. I know this isn't ideal :)

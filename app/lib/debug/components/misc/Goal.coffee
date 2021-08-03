Component = require 'lib/world/component'

module.exports = class Goal extends Component
  @className: "Goal"

  update: ->
    for thang in @world.thangs when thang.acts and thang.exists and not thang.isLand and thang isnt @ and @contains(thang)
      @publishNote "thang-touched-goal",
        actor: thang
        touched: @
Component = require 'lib/world/component'

module.exports = class Debugs extends Component
  @className: 'Debugs'

  debug: (args...) ->
    @sayWithoutBlocking? args.join(' ')
    console.log args...
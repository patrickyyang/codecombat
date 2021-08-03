Component = require 'lib/world/component'

module.exports = class Shoveable extends Component
  @className: 'Shoveable'
  chooseAction: ->
    @attack @
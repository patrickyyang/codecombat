Component = require 'lib/world/component'

module.exports = class AttacksAtRange extends Component
  @className: 'AttacksAtRange'
  chooseAction: ->
    @attack @
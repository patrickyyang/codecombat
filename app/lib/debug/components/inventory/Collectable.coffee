Component = require 'lib/world/component'

module.exports = class Collectable extends Component
  @className: "Collectable"
  isCollectable: true

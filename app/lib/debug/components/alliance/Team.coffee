Component = require 'lib/world/component'

# These will go onto abstract Team Thangs.
module.exports = class Team extends Component
  @className: "Allied"
  constructor: (config) ->
    super config
    @superteam ?= @team

  attach: (thang) ->
    # Don't call super attach, since we aren't copying the prop to thang, but to its world.
    # Or maybe to Alliance System?
    # Or maybe we do leave the abstract Thang around?
    # Should also come with Tinted so we can colorize teams
    # TODO

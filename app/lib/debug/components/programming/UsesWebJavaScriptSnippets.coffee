Component = require 'lib/world/component'

module.exports = class UsesWebJavaScriptSnippets extends Component
  @className: 'UsesWebJavaScriptSnippets'
  chooseAction: ->
    @attack @
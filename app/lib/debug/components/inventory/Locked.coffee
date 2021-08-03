Component = require 'lib/world/component'

module.exports = class Locked extends Component
  @className: 'Locked'

  okToCollect: (collector) ->
    key = collector.peekItem?()
    console.log "okToCollect", @id, collector.id, @isLocked, key?.id
    if @isLocked and key and (key.spriteName.search("Key") isnt -1)
      @isLocked = false
      key = collector.popItem()
      key.setExists false
      return true
    else
      collector.sayWithoutBlocking? "I need a key.", 1

    false
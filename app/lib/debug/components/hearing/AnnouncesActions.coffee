Component = require 'lib/world/component'

module.exports = class AnnouncesActions extends Component
  @className: 'AnnouncesActions'

  attach: (thang) ->
    super thang
    thang.announcedActionMessages = []

  announceAction: (action, force=false) ->
    oldAction = @action
    action ?= @action
    return if not action or action is 'idle'
    return unless @say
    return if @sayMessage and not (@sayMessage in @announcedActionMessages) and not force  # Don't overwrite their stuff
    message = action
    message += ' ' + @target.id if @target
    if message is 'attack Hero Placeholder'
      return if message in @announcedActionMessages
      @announcedActionMessages.push message unless force
      messages = ['For Thoktar!', 'Bones!', 'Behead!', 'Destroy!', 'Die, humans!']
      @actionAnnounceRandomSeed ?= @world.rand.randn()
      message = messages[@actionAnnounceRandomSeed % messages.length]
    else
      @announcedActionMessages.push message unless force
    @clearSpeech()
    @sayWithoutBlocking message, 2
    @action = oldAction

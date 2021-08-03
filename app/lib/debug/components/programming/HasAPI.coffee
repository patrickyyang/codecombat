Component = require 'lib/world/component'

# https://gist.github.com/keenahn/3184241
slugify = (str) ->
  # Trim and force lowercase
  str = str.replace(/^\s+|\s+$/g, "").toLowerCase()

  # Remove accents, swap ñ for n, etc
  from = "àáäâèéëêìíïîòóöôùúüûñç·/_,:;"
  to   = "aaaaeeeeiiiioooouuuunc------"
  for i in [i .. from.length]
    str = str.replace(new RegExp(from.charAt(i), "g"), to.charAt(i))
    
  # Remove invalid chars, collapse whitespace and replace by -, collapse dashes
  str.replace(/[^a-z0-9 -]/g, "").replace(/\s+/g, "-").replace(/-+/g, "-")

module.exports = class HasAPI extends Component
  @className: 'HasAPI'
  attach: (thang) ->
    super thang
    # "ogre-munchkin-m-2" -> "munchkin"
    if thang.spriteName in ['Ogre M', 'Ogre F']
      thang.type ||= 'ogre'
    else
      thang.type ||= slugify(thang.spriteName).replace(///(
          ^ogre- |
          ^human- |
          (-[mf])?(-[0-9]+)?$
        )///g, '')

  block: ->
    @future?.resolve esper.Value.fromNative 'interrupted'
    FutureValue = esper.FutureValue  #IE14 had troubles calling (esper.FutureValue())
    @future = new FutureValue()
    return @future
  
  update: ->
    # TODO: This makes return values not work when interrupted by an event thread
    return unless @waitingToUnblock and @actionHeats.all <= @world.dt
    @finishUnblocking()
    
  finishUnblocking: ->
    return unless aether = @world.userCodeMap['Hero Placeholder']?.plan  # TODO: fix the jank
    return unless aether.esperEngine
    @future.resolve aether.esperEngine.realm.makeForForeignObject @waitingToUnblockReturnValue
    @future = undefined
    @currentPlanMethodResolved = true if @plan
    @waitingToUnblock = undefined
    @waitingToUnblockReturnValue = undefined
  
  unblock: (returnValue) ->
    return unless @future
    # Check if we're nearing the end our of cooldown to actually check if we should unblock, else create a 'promise' to resolve it later
    # This is so that we make sure the action remains consistent throughout our action cooldown
    if @actionHeats.all <= @world.dt
      @finishUnblocking()
      
    else
      # TODO: This makes return values not work when interrupted by an event thread
      @waitingToUnblock = true
      @waitingToUnblockReturnValue = returnValue

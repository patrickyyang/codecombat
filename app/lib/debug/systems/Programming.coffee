System = require 'lib/world/system'

module.exports = class Programming extends System
  constructor: (world, config) ->
    super world, config
    if config.showVariableNames
      @variableThangs = @addRegistry (thang) -> thang.isSelectable

  update: ->
    # Paranoia!
    try
      @updateVariableNames()
    catch e
      console.log e.stack
      
    hash = 0
    return hash
  
  updateVariableNames: ->
    return unless @showVariableNames
    return unless aether = @world.userCodeMap['Hero Placeholder']?.plan  # TODO: fix the jank
    return unless aether?.esperEngine?.evaluator
    evalu = aether.esperEngine.evaluator
    
    for f in evalu.frames
      continue unless f.scope?
      scope = f.scope
      @bestScope = scope
      break
        
    return unless scope ?= @bestScope
    
    list = []
    @
    o = scope
    while o?
      list = list.concat scope.getVariableNames()
      o = o.parent

    vars = {}
    for key in list when not /^(__|self|hero|game$)/.test(key)
      v = scope.get(key)
      if v.native?.isThang
        # To prevent labeling for specific thangs and the pet is a special case
        if v.native.preventLabel or (/^pet$/.test(key) and v.native.preventLabel isnt false)
          continue
        vars[key] = v.native
      else if v.properties
        for subkey of v.properties
          subc = v.properties[subkey]?.value
          if subc?.native?.isThang isnt -1
            vars[key + "[" + subkey + "]"] = subc.native

    for thang in @variableThangs
      names = []
      
      for key in Object.keys(vars)
        names.push key if vars[key] is thang
        
      if names.length > 0
        unless thang.variableNames?
          thang.addTrackedProperties ['variableNames', 'string']
        thang.keepTrackedProperty 'variableNames'
        thang.variableNames = names.join(", ")
      else if thang.variableNames?
        thang.keepTrackedProperty 'variableNames'
        thang.variableNames = false
        
    
  finish: (thangs) ->
    for thang in thangs when thang.isProgrammable
      userCode = @world.userCodeMap[thang.id] ? {}
      for methodName, aether of userCode when aether.ast
        try
          linesUsed = aether.getStatementCount()
        catch e
          linesUsed = 0
        thang.linesOfCodeUsed = linesUsed
        thang.publishNote? 'lines-of-code-counted', linesUsed: linesUsed

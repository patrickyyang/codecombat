Component = require 'lib/world/component'

module.exports = class PropertyErrorHelper extends Component
  @className: 'PropertyErrorHelper'

  # Helper proxy to detect and warn about common mistakes when setting properties on game dev objects.
  
  initialize: ->
    @checkProperties = ['maxSpeed', 'attackDamage', 'health', 'maxHealth', 'scale', 'behavior', 'pos', 'spawnType', 'spawnDelay']
    @scoreFuzziness = 0.8
    @acceptMatchThreshold = 0.5

    @proxyHandler = {
      set: (ob, prop, value) =>
        # Might need something like this? but it seems to work without it.
        # esper = /^esper_(.+)/
        # if esper.test(prop)
        #   prop = prop.match(esper)[1]
        errorMsg = @checkForProbableError ob, prop
        if errorMsg
          throw new Error(errorMsg)
          return false
        ob[prop] = value
        return true
    }

  proxifyThang: (thang, handler = @proxyHandler) ->
    # TODO: check out ArgumentError (or others) to see if we need to do other stuff like Make a userCodeProblem
    # TODO: add a getter that does similar kinds of checking
    # console.log "PROXY proxifyThang", thang.id
    if(typeof Proxy != 'undefined')
      proxy = new Proxy(thang, handler) 
    else
      proxy = thang

  checkForProbableError: (thang, target) ->
    return "" if thang[target]?
    return "" if thang.ignorePropertyTypoChecks or /^esper_/.test(target)
    commonMistakes = @checkProperties
    hint = @getExactMatch target, commonMistakes, (match) ->
      return ""
    hint ?= @getNoCaseMatch target, commonMistakes, (match) ->
      "You wrote: #{target}, did you mean: #{match}? Be sure to capitalize properly!"
    hint ?= @getScoreMatch target, commonMistakes, (match) ->
      "You wrote: #{target}, did you mean #{match}?"
    hint


  getExactMatch: (target, candidates, msgFormatFn) ->
    return unless candidates?
    msgFormatFn target if target in candidates

  getNoCaseMatch: (target, candidates, msgFormatFn) ->
    return unless candidates?
    candidatesLow = (s.toLowerCase() for s in candidates)
    msgFormatFn(candidates[index]) if (index = candidatesLow.indexOf(target)) >= 0
    
  getScoreMatch: (target, candidates, msgFormatFn) ->
    return unless string_score?
    [closestMatch, closestScore, msg] = ['', 0, '']
    for match in candidates
      matchScore = match.score target, @scoreFuzziness
      [closestMatch, closestScore, msg] = [match, matchScore, msgFormatFn(match)] if matchScore > closestScore
    msg if closestScore >= @acceptMatchThreshold

  
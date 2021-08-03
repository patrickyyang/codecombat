Component = require 'lib/world/component'

module.exports = class TestReferee extends Component
  @className: 'TestReferee'

  attach: (thang) ->
    super(thang)
    thang.testsPassing = true
    
  startTests: ->
    @world.testLog = []
    @testStatus = []
    @testLog "START:", @world.levelID


  it: (should, fn) ->
    @world.currentTestGroup = should
    fn()
    @finishOneTest()
    
  assertTrue: (bool) ->
    unless bool
      @testsPassing = false
      @testLog "FAILED assertion: expected", bool, "to be true"

  assertFalse: (bool) ->
    if bool
      @testLog "FAILED assertion: expected", bool, "to be false"  
      @testsPassing = false


  finishOneTest: ->
    unless @testsPassing
      @testLog "*** FAILED:", @world.currentTestGroup
      @testStatus.push false
      @setGoalState 'pass-tests', 'failure'
    else
      @testStatus.push true
      @testLog "PASSED:", @world.currentTestGroup

    # Reset for next text
    @testsPassing = true
    
  finishTests: ->
    state = (if @testStatus.indexOf(false) is -1 then 'success' else 'failure')
    @testLog "END:", @world.levelID, state
    @setGoalState 'pass-tests', state

  testLog: (msg...) ->
    message = msg.join(' ')
    message = "[TEST] " + message
    #@world.testLog.push message
    console.log message
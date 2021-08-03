Component = require 'lib/world/component'

module.exports = class Programmable extends Component
  @className: 'Programmable'
  isProgrammable: true
  isProgrammableDisabled: false
  erroredOut: false  # Whether it has already had its error; could refactor this to just store one value instead of one per frame
  errorsOut: false  # Non-temporal: whether it errors out at all in this World
  extraProgrammableProperties: ['validateReturn', 'id', 'spriteName', '_aetherUserInfo', '_aetherAPIOwnMethodsAllowed', '_aetherShouldSkipFlow']
  attach: (thang) ->
    @programmableProperties = (thang.programmableProperties ? []).concat (@programmableProperties ? [])
    super thang
    @programmableProperties = (thang.moreProgrammableProperties ? []).concat @programmableProperties
    thang.apiUserProperties ?= []
    thang.apiProperties ?= []
    thang.apiMethods ?= []
    thang.apiOwnMethods ?= []
    for prop in _.union @programmableProperties, @extraProgrammableProperties when not (prop in thang.apiUserProperties) and not (prop in thang.apiMethods)
      # https://github.com/codecombat/codecombat/issues/1134 - non-destructive HasAPI functions are done as apiMethods, destructive Programmable functions are done as apiOwnMethods
      api = if _.isFunction(thang[prop]) then thang.apiOwnMethods else thang.apiProperties
      # We'll move methods from apiProperties to apiMethods in Item if we define it later.
      api.push prop unless prop in api

    thang.addTrackedProperties ["erroredOut", "boolean"]
    thang.addTrackedFinalProperties "errorsOut"
    thang.publishedUserCodeProblems = {}

    for methodName, method of thang.programmableMethods
      thang.deserializeAether methodName

  deserializeAether: (methodName) ->
    # Now we do a complicated dance to pull together 1) the host methods and 2) the related serialized Aether instances
    method = @programmableMethods[methodName]
    @world.userCodeMap[@id] ?= {}
    userCode = @world.userCodeMap[@id]
    unless userCode[methodName]
      method.originalSource = @getMethodSource(methodName).original
      method.source ?= method.originalSource   # hmm, needed?
      method.name = methodName
      method.permissions ?= {read: [], readwrite: [@team ? "humans"]}

    return unless aether = userCode[methodName]
    unless aether instanceof Aether
      # Deserialize it, but leave the original around for deserializing copies, and give each their own runtime state.
      deserialized = Aether.deserialize aether
      deserialized.serializedAether = aether
      aether.flow = {}
      aether.metrics = {}
      aether.style = _.cloneDeep aether.style
      aether.problems = _.cloneDeep aether.problems
      aether = userCode[methodName] = deserialized
      aether.whileLoopMarker = => @world.frames.length
    if aether?.problems.errors.length
      @erroredOut = @errorsOut = true
      @keepTrackedProperty 'erroredOut'
    for problem in aether?.getAllProblems() ? [] when not @publishedUserCodeProblems[problem.message]
      @publishNote 'user-code-problem', problem: problem
      @publishedUserCodeProblems[problem.message] = problem
    @replaceMethodCode methodName, aether
    aether

  replaceMethodCode: (methodName, aether) ->
    # User replaces original method source while preserving component chain
    method = @programmableMethods[methodName]
    methodChain = @createMethodChain methodName
    methodSource = aether?.pure ? ''
    method.source = methodSource
    unless methodSource.length
      # If source is '' (possibly because there are errors), then there's not much to do.
      methodChain.user = ->  # no-op when this method is called
      if aether?.problems.errors.length
        # Code was eliminated because of transpile error
        @erroredOut = @errorsOut = true
        @keepTrackedProperty 'erroredOut'
      for problem in aether?.getAllProblems() ? [] when not @publishedUserCodeProblems[problem.message]
        @publishNote 'user-code-problem', problem: problem
        @publishedUserCodeProblems[problem.message] = problem
      return
    inner = aether.createFunction()
    @addGlobals aether
    outer = (args...) ->
      return if @checkExecutionLimit(methodName, aether) > 0
      @_aetherUserInfo = aether._userInfo = {time: @world.age}
      @_aetherAPIOwnMethodsAllowed ?= 0
      ++@_aetherAPIOwnMethodsAllowed  # Not just true/false, but level of method nesting.
      @actionsChosenThisCall = 0 if methodName is 'chooseAction'
      #console.log @id, 'going for it with apiMethods', @apiMethods, 'apiProperties', @apiProperties, 'apiUserProperties', @apiUserProperties, 'apiOwnMethods', @apiOwnMethods
      try
        result = @validateReturn methodName, inner.apply(@, args)
      catch error
        @handleProgrammingError error, methodName
        @replaceMethodCode methodName, null  # no-op when this method is called
        result = null
      --@_aetherAPIOwnMethodsAllowed  # Don't let other Thangs call this Thang's API methods
      @actionsChosenThisCall = null
      return result
    methodChain.user = outer
    
  addGlobals: (aether) ->
    if @isGameReferee
      aether.addGlobal? 'game', @
    else
      aether.addGlobal? 'hero', @
      if aether.language.id is 'python'
        aether.addGlobal? 'self', @

  validateReturn: (methodName, ret) ->
    @[methodName + 'ValidateReturn']?(ret)
    ret
    
  getAetherForMethod: (methodName) ->
    if @world?.userCodeMap?[@id]?[methodName]?
      @world.userCodeMap[@id][methodName]
  
  addAetherProblemForMethod: (problem, methodName) ->
    problem.userInfo.thangID = @id
    problem.userInfo.methodName = methodName
    problem.message = problem.message.replace /(Object )?#<Object>/, @id  # TODO: this doesn't work in nested methods
    problem.userInfo.key = [@id, methodName, problem.message].join("|")
    problem.userInfo.age = @world.age
    aether = @getAetherForMethod methodName
    aether.addProblem problem
    console.log @id, "had new Programmable problem:", methodName, problem.message, problem.userInfo.age if problem.level is 'error'
    @world.addError problem if problem.level is 'error'
    unless @publishedUserCodeProblems[problem.message]
      @publishNote 'user-code-problem', problem: problem
      @publishedUserCodeProblems[problem.message] = problem

  handleProgrammingError: (error, methodName) ->
    @erroredOut = @errorsOut = true
    @keepTrackedProperty 'erroredOut'
    aether = @getAetherForMethod methodName
    problem = aether.createUserCodeProblem type: 'runtime', error: error
    @addAetherProblemForMethod problem, methodName

  checkExecutionLimit: (methodName, aether) ->
    # If they can only use, say, 1000 execution units per chooseAction call, and they use 2300, then we delay chooseAction by 2 frames.
    # Really only designed to work with chooseAction.
    method = @programmableMethods[methodName]
    return 0 unless method.executionLimit and aether.metrics
    method.executionUsed ?= 0
    lastUsed = method.executionUsed
    totalUsed = aether.metrics.statementsExecuted ? 0
    justUsed = totalUsed - lastUsed
    method.executionUsed = Math.min totalUsed, method.executionUsed + method.executionLimit
    overuse = justUsed - method.executionLimit
    if overuse > 0 and not @executionLimitExceeded
      @executionLimitExceeded = true
      #console.log aether.metrics.callsExecuted, "lastUsed", lastUsed, "totalUsed", totalUsed, "justUsed", justUsed, "so bumping up to", method.executionUsed, "with overuse of", justUsed - method.executionLimit
      age = @world.age
      message = "Exceeded per-call execution limit with #{justUsed} / #{method.executionLimit} statements.\nYour code will run less often to compensate."
      fakeError = {name: "ExecutionLimitExceeded", message: message, toString: -> message}
      problem = aether.createUserCodeProblem type: 'runtime', level: 'info', error: fakeError
      @addAetherProblemForMethod problem, methodName
    justUsed - method.executionLimit

  debug: (args...) ->
    console.log args...
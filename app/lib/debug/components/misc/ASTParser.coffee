Component = require 'lib/world/component'

module.exports = class ASTParser extends Component
  @className: 'ASTParser'

  
  initParser: ->
    aether = @world?.userCodeMap['Hero Placeholder']?.plan
    @codeLanguage = aether.language.id
    conceptEngine = new esper.Engine()
    conceptEngine.loadAST(aether.ast)
    @esperAST2 = conceptEngine.evaluator.ast
    @esperAST2.body.shift() if @codeLanguage is 'python'

    @ALIAS = 
      "==": 'BinaryExpression[operator="=="],BinaryExpression[operator="==="]'
      "-": ['BinaryExpression', (n) =>  n.operator is '-']
      "-=": ['AssignmentExpression', (n) =>  n.operator is '-=']
      "stringConcat": 
        'javascript': ['BinaryExpression', (n) =>  n.operator is '+' and (typeof(n.right?.value) is "string" or typeof(n.left?.value) is "string")]
        'python': ['CallExpression.arguments', (exp) => exp.srcName?.match(/ops\.add/) and _.some(exp.arguments, (arg) => typeof(arg.value) is "string")]

  astFind: (selector, fn) ->
    unless @esperAST2
      @initParser()

    alias = @ALIAS[selector]
    if alias
      if _.isPlainObject(alias) and alias[@codeLanguage]
        alias = alias[@codeLanguage]
      if _.isArray(alias)
        selector = alias[0]
        fn = alias[1]
      else
        selector = alias

    if fn
      return _.filter(@esperAST2.find(selector), fn)
      
    @esperAST2.find(selector)
  
  # For debugging and logging
  astPrint: (expression, indent=0) ->
    pre = ""
    for i in [0...indent]
      pre += "- "
    for k, v of expression
      if typeof(v) is "function"
        console.log(pre, k, "function")
      else
        console.log(pre, k, v)
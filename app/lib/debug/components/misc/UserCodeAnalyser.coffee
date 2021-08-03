Component = require 'lib/world/component'

module.exports = class UserCodeAnalyser extends Component
  @className: 'UserCodeAnalyser'
  
  # Search through a plan's AST to find the part represents the player's code.
  findBody: (plan) ->
    return null if not plan
    #src = plan.raw
    abody = plan.ast?.body
    if not abody
      console.log('No body! Maybe had problems parsing?')
      return null
    return abody unless @lang is 'coffeescript'
    rv = null
    for b in abody
      c = b?.body?.body
      if not c
        c = b?.expression?.right?.body?.body
      if c
        rv = c
        break
    return rv

  # Format an AST expression as human-readable(-ish) pseudocode.
  formatExpression: (o, ctx='') ->
    if not o
      return ' '
    if not o.type
      return '' + o
    tag = ctx + '.' + o.type
    switch o.type
      when 'ThisExpression'
        return 'this'

      when 'Literal'
        return '' + o.value #o.raw

      when 'Identifier'
        return o.name

      when 'MemberExpression'
        mo = @formatExpression(o.object, tag)
        mp = @formatExpression(o.property, tag)
        return mo + '.' + mp

      when 'AssignmentExpression'
        lhs = @formatExpression(o.left, tag)
        rhs = @formatExpression(o.right, tag)
        return lhs + '=' + rhs

      when 'VariableDeclaration'
        buf = []
        for decl in o.declarations
          vn = decl.id.name
          vv = @formatExpression(decl.init, vn)
          buf.push(vn + '=' + vv)
        return buf.join(',')

      when 'CallExpression'
        cc = @formatExpression(o.callee, tag)
        ca = (@formatExpression(i, tag) for i in o.arguments).join(',')
        return cc + '(' + ca + ')'

      when 'NewExpression'
        nc = @formatExpression(o.callee, tag)
        na = (@formatExpression(i, tag) for i in o.arguments).join(',')
        return nc + '(' + na + ')'

      when 'BinaryExpression'
        lhs = @formatExpression(o.left, tag)
        rhs = @formatExpression(o.right, tag)
        return lhs + o.operator + rhs

      when 'FunctionExpression'
        fa = (@formatExpression(i, tag) for i in o.params).join(',')
        fb = @formatExpression(o.body)
        return o.id + '(' + fa + '){' + fb + '}'

      when 'ArrayExpression'
        aa = (@formatExpression(i, tag) for i in o.elements).join(',')
        return '[' + aa + ']'

      when 'ExpressionStatement'
        return 'expr(' + @formatExpression(o.expression) + ')'

      when 'BlockStatement'
        ba = (@formatExpression(i, tag) for i in o.body).join('; ')
        return '{' + ba + '}'

      when 'FunctionDeclaration'
        fName = o.id?.name
        paramNames = (p.name for p in o.params when p.name)
        return 'funcDef ' + fName + '(' + paramNames.join(',') + ')'
      else
        @dumpKeys(o, ctx)
        return o.type
    return '' + o


  # What's in this object?
  dumpKeys: (o, ctx='') ->
    if not o
      console.log(ctx, 'nothing', o)
    for i in Object.keys(o)
      console.log(ctx, i, o[i])
      
  collectCodeBlocks: (block, depth=100, codeBlocks) ->
    codeBlocks ?= []
    if not block or depth <= 0
      return codeBlocks
    codeBlocks.push(block)
    if block.length
      for exp in block
        @collectCodeBlocks(exp, depth - 1, codeBlocks)
    if block.body
      @collectCodeBlocks(block.body, depth - 1, codeBlocks)
    if block.callee
      @collectCodeBlocks(block.callee, depth - 1, codeBlocks)
    if block.expression
      @collectCodeBlocks(block.expression, depth - 1, codeBlocks)
    if block.consequent
      @collectCodeBlocks(block.consequent, depth - 1, codeBlocks)
    codeBlocks
      
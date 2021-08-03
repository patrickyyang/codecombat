Component = require 'lib/world/component'

module.exports = class PlanReferee extends Component
  @className: 'PlanReferee'

  attach: (thang) ->
    super(thang)
  #chooseAction: ->
  #  null


  # Return an array of lines of code (as strings) that contain the given search string.
  planLinesContainingString: (query) ->
    rv = []
    f = (expr, type, depth) =>
      #console.log('|', @planIndent(expr, depth))
      if expr.search(query) != -1
        rv.push(expr)
    @planWalkLogicalLines(f)
    return rv

  # Return an array of nodes of the given expression type.
  planNodesByType: (xtype) ->
    return [] #TODO

  # Walk through the body and call the callback for each logical line of code.
  # callback should be a function "f(expression, type, depth)",
  # where expression is the code to be evaluated (see planFormatExpression()),
  # type is the expression type label, and depth is the nesting level.
  planWalkLogicalLines: (callback) ->
    body = @planFindBody()
    return unless body
    for expr in body
      @_planWalkLogicalLines(expr, callback, 0)
  _planWalkLogicalLines: (o, callback, depth) ->
    return unless o
    return unless o.type
    switch o.type
      when 'BlockStatement'
        for expr in o.body
          # transparently go through the block, process all children at the same depth
          @_planWalkLogicalLines(expr, callback, depth)

      when 'IfStatement', 'ConditionalExpression'
        callback(@planFormatExpression(o), o.type, depth)
        @_planWalkLogicalLines(o.consequent, callback, depth + 1)
        if o.alternate
          callback(@planFormatExpression({'type':'ElseStatement'}), 'ElseStatement', depth)
          @_planWalkLogicalLines(o.alternate, callback, depth + 1)

      when 'WhileStatement', 'FunctionExpression', 'FunctionDeclaration', 'ForStatement', 'ForInStatement'
        callback(@planFormatExpression(o), o.type, depth)
        @_planWalkLogicalLines(o.body, callback, depth + 1)

      else
        callback(@planFormatExpression(o), o.type, depth)

  # Format an AST node as human-readable(-ish) pseudocode,
  # either for eyeballing or for searching for substrings.
  planFormatExpression: (o) ->
    return ' ' unless o
    return ('' + o) unless o.type
    switch o.type
      when 'EmptyStatement'
        return ''
      when 'ThisExpression'
        return 'this'
      when 'Literal'
        return '"' + o.value + '"' #o.raw
      when 'Identifier'
        return o.name
      when 'ExpressionStatement'
        return 'expr(' + @planFormatExpression(o.expression) + ')'

      when 'MemberExpression'
        mo = @planFormatExpression(o.object)
        mp = @planFormatExpression(o.property)
        return mo + '.' + mp

      when 'Property'
        ka = @planFormatExpression(o.key)
        va = @planFormatExpression(o.value)
        return ka + ':' + va

      when 'AssignmentExpression'
        lhs = @planFormatExpression(o.left)
        rhs = @planFormatExpression(o.right)
        return lhs + '=' + rhs

      when 'VariableDeclaration'
        buf = []
        for decl in o.declarations
          vn = decl.id.name
          vv = @planFormatExpression(decl.init, vn)
          buf.push(vn + '=' + vv)
        return buf.join(',')

      when 'CallExpression'
        cc = @planFormatExpression(o.callee)
        ca = (@planFormatExpression(i) for i in o.arguments).join(',')
        return cc + '(' + ca + ')'

      when 'NewExpression'
        nc = @planFormatExpression(o.callee)
        na = (@planFormatExpression(i) for i in o.arguments).join(',')
        return 'new ' + nc + '(' + na + ')'

      when 'BinaryExpression', 'LogicalExpression'
        lhs = @planFormatExpression(o.left)
        rhs = @planFormatExpression(o.right)
        return '(' + lhs + ')' + o.operator + '(' + rhs + ')'

      when 'UnaryExpression', 'UpdateExpression'
        oa = @planFormatExpression(o.operator)
        aa = @planFormatExpression(o.argument)
        if o.prefix
          return oa + '(' + aa + ')'
        else
          return '(' + aa + ')' + oa

      when 'FunctionExpression', 'FunctionDeclaration'
        fi = @planFormatExpression(o.id)
        fa = (@planFormatExpression(i) for i in o.params).join(',')
        #fb = @planFormatExpression(o.body)
        return 'function ' + fi + '(' + fa + '):'

      when 'ArrayExpression'
        aa = (@planFormatExpression(i) for i in o.elements).join(',')
        return '[' + aa + ']'

      when 'ObjectExpression'
        pa = (@planFormatExpression(i) for i in o.properties).join(',')
        return '{' + pa + '}'

      when 'IfStatement', 'ConditionalExpression'
        ta = @planFormatExpression(o.test)
        #ca = @planFormatExpression(o.consequent)
        #aa = @planFormatExpression(o.alternate)
        return 'if(' + ta + '):'

      when 'ElseStatement'
        # This is a fake statement type inserted to break up the consequent and alternate of an IfStatement.
        return 'else:'

      when 'ForStatement'
        ia = @planFormatExpression(o.init)
        ta = @planFormatExpression(o.test)
        ua = @planFormatExpression(o.update)
        #ba = @planFormatExpression(o.body)
        return 'for (' + ia + ';' + ta + ';' + ua + '):'

      when 'ForInStatement'
        la = @planFormatExpression(o.left)
        ra = @planFormatExpression(o.right)
        #ba = @planFormatExpression(o.body)
        return 'for (' + la + ') in (' + ra + '):'

      when 'WhileStatement'
        ta = @planFormatExpression(o.test)
        #ba = @planFormatExpression(o.body)
        return 'while ' + ta + ':'

      when 'ContinueStatement'
        return 'continue'
      when 'BreakStatement'
        return 'break'

      when 'ReturnStatement'
        if o.argument
          return 'return ' + @planFormatExpression(o.argument)
        else
          return 'return'

      when 'BlockStatement'
        ba = (@planFormatExpression(i) for i in o.body).join('; ')
        return '{' + ba + '}'

      else
        @planDumpKeys(o)
        return o.type
    return '' + o

  # What's in this object?
  planDumpKeys: (o) ->
    if not o
      console.log('nothing', o)
    for i in Object.keys(o)
      console.log(i, o[i])

  planIndent: (s, depth, tabwidth=4) ->
    rv = ''+s
    for i in [0...depth]
      for j in [0...tabwidth]
        rv = ' ' + rv
    return rv

  # Search through a plan's AST to find the body block, i.e., the actual player code
  planFindBody: () ->
    plan = @world.userCodeMap['Hero Placeholder'].plan
    lang = plan.language.id
    #src = plan.raw
    abody = plan.ast?.body
    if not abody
      console.log('No body! Maybe had problems parsing?')
      return null
    return abody unless lang is 'coffeescript'
    rv = null
    for b in abody
      c = b?.body?.body
      if not c
        c = b?.expression?.right?.body?.body
      if c
        rv = c
        break
    return rv

# TODO: handle all of these expression types, maybe?
# ArrayPattern
# ArrowFunctionExpression
# CatchClause
# ClassBody
# ClassDeclaration
# ClassExpression
# ClassHeritage
# ComprehensionBlock
# ComprehensionExpression
# DebuggerStatement
# DoWhileStatement
# ExportDeclaration
# ExportBatchSpecifier
# ExportSpecifier
# ForOfStatement
# ImportDeclaration
# ImportSpecifier
# LabeledStatement
# LogicalExpression
# MethodDefinition
# ModuleDeclaration
# ObjectExpression
# ObjectPattern
# Program
# SequenceExpression
# SpreadElement
# SwitchCase
# SwitchStatement
# TaggedTemplateExpression
# TemplateElement
# TemplateLiteral
# ThrowStatement
# TryStatement
# VariableDeclarator
# WithStatement
# YieldExpression

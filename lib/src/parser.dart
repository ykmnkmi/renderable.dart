import 'package:meta/meta.dart';

import 'lexer.dart';
import 'nodes.dart';
import 'configuration.dart';
import 'reader.dart';

class Parser {
  Parser(this.configuration)
      : endRulesStack = <List<String>>[],
        tagStack = <String>[];

  final Configuration configuration;

  final List<List<String>> endRulesStack;

  final List<String> tagStack;

  bool isTupleEnd(TokenReader reader, [List<String>? extraEndRules]) {
    switch (reader.current.type) {
      case 'variable_end':
      case 'block_end':
      case 'rparen':
        return true;
      default:
        if (extraEndRules != null && extraEndRules.isNotEmpty) {
          return reader.current.testAny(extraEndRules);
        }

        return false;
    }
  }

  List<Node> parse(String template, {String? path}) {
    final tokens = Lexer(configuration).tokenize(template, path: path);
    final reader = TokenReader(tokens);
    return scan(reader);
  }

  @protected
  List<Node> scan(TokenReader reader) {
    return subParse(reader);
  }

  List<Node> subParse(TokenReader reader, {List<String>? endTokens}) {
    final buffer = <Node>[];
    final nodes = <Node>[];

    if (endTokens != null) {
      endRulesStack.add(endTokens);
    }

    void flushData() {
      if (buffer.isNotEmpty) {
        nodes.add(Output(buffer.toList()));
        buffer.clear();
      }
    }

    try {
      while (!reader.current.test('eof')) {
        final token = reader.current;

        switch (token.type) {
          case 'data':
            buffer.add(Data(token.value));
            reader.next();
            break;
          case 'variable_begin':
            reader.next();
            buffer.add(parseTuple(reader));
            reader.expect('variable_end');
            break;
          case 'block_begin':
            flushData();
            reader.next();

            if (endTokens != null && reader.current.testAny(endTokens)) {
              return nodes;
            }

            nodes.add(parseStatement(reader));
            reader.expect('block_end');
            break;
          default:
            throw 'unexpected token: $token';
        }
      }

      flushData();
    } finally {
      if (endTokens != null) {
        endRulesStack.removeLast();
      }
    }

    return nodes;
  }

  Node parseStatement(TokenReader reader) {
    final token = reader.current;

    if (!token.test('name')) {
      throw 'tag name expected';
    }

    tagStack.add(token.value);
    var popTag = true;

    try {
      switch (token.value) {
        case 'set':
          return parseSet(reader);
        case 'for':
          return parseFor(reader);
        case 'if':
          return parseIf(reader);
        default:
          popTag = false;
          tagStack.removeLast();
          throw 'unknown tag: ${token.value}';
      }
    } finally {
      if (popTag) {
        tagStack.removeLast();
      }
    }
  }

  List<Node> parseStatements(TokenReader reader, List<String> endTokens, {bool dropNeedle = false}) {
    reader.skipIf('colon');
    reader.expect('block_end');

    final nodes = subParse(reader, endTokens: endTokens);

    if (reader.current.test('eof')) {
      throw 'unexpected end of file';
    }

    if (dropNeedle) {
      reader.next();
    }

    return nodes;
  }

  Statement parseSet(TokenReader reader) {
    reader.expect('name', 'set');

    final target = parseAssignTarget(reader, withNameSpace: true);

    if (reader.skipIf('assign')) {
      final expression = parseTuple(reader);
      return Assign(target, expression);
    }

    final body = parseStatements(reader, <String>['name:endset'], dropNeedle: true);
    return AssignBlock(target, body);
  }

  For parseFor(TokenReader reader) {
    reader.expect('name', 'for');

    final target = parseAssignTarget(reader, extraEndRules: <String>['name:in']);

    reader.expect('name', 'in');

    final iterable = parseTuple(reader, withCondition: false);

    var hasLoop = false;

    void visit(Node node) {
      if (node is Name) {
        if (node.name == 'loop') {
          hasLoop = true;
        }
      } else if (node is For) {
        return;
      } else {
        node.visitChildNodes(visit);
      }
    }

    Test? test;

    if (reader.skipIf('name', 'if')) {
      final expression = parseExpression(reader);
      expression.visitChildNodes(visit);
      test = expression is Test ? expression : Test('defined', expression);
    }

    final recursive = reader.skipIf('name', 'recursive');
    final body = parseStatements(reader, <String>['name:endfor', 'name:else']);

    if (!hasLoop) {
      body.forEach(visit);
    }

    List<Node>? orElse;

    if (reader.next().test('name', 'else')) {
      orElse = parseStatements(reader, <String>['name:endfor'], dropNeedle: true);
    }

    return For(target, iterable, body, hasLoop: hasLoop, orElse: orElse, test: test, recursive: recursive);
  }

  If parseIf(TokenReader reader) {
    reader.expect('name', 'if');

    final test = parseTuple(reader, withCondition: false);
    final body = parseStatements(reader, <String>['name:elif', 'name:else', 'name:endif']);
    final root = If(test is Test ? test : Test('defined', test), body);
    var node = root;

    while (true) {
      final tag = reader.next();

      if (tag.test('name', 'elif')) {
        final test = parseTuple(reader, withCondition: false);
        final body = parseStatements(reader, <String>['name:elif', 'name:else', 'name:endif']);
        node.nextIf = If(test is Test ? test : Test('defined', test), body);
        node = node.nextIf!;
        continue;
      }

      if (tag.test('name', 'else')) {
        root.orElse = parseStatements(reader, <String>['name:endif'], dropNeedle: true);
      }

      break;
    }

    return root;
  }

  Expression parseAssignTarget(TokenReader reader, {List<String>? extraEndRules, bool nameOnly = false, bool withNameSpace = false, bool withTuple = true}) {
    Expression target;

    if (withNameSpace && reader.look().test('dot')) {
      final nameSpace = reader.expect('name');

      reader.next(); // skip dot

      final attribute = reader.expect('name');
      target = NameSpaceReference(nameSpace.value, attribute.value);
    } else if (nameOnly) {
      final name = reader.expect('name');
      target = Name(name.value, context: AssignContext.store);
    } else {
      if (withTuple) {
        target = parseTuple(reader, simplified: true, extraEndRules: extraEndRules);
      } else {
        target = parsePrimary(reader);
      }

      if (target is CanAssign) {
        target.context = AssignContext.store;
      } else {
        throw 'can\'t assign to ${target.runtimeType}';
      }
    }

    return target;
  }

  Expression parseExpression(TokenReader reader, [bool withCondition = true]) {
    return withCondition ? parseCondition(reader) : parseOr(reader);
  }

  Expression parseCondition(TokenReader reader, [bool withCondExpr = true]) {
    var expression1 = parseOr(reader);

    while (reader.skipIf('name', 'if')) {
      var expression2 = parseOr(reader);

      if (reader.skipIf('name', 'else')) {
        expression1 = Condition(expression2, expression1, parseCondition(reader));
      } else {
        expression1 = Condition(expression2, expression1);
      }
    }

    return expression1;
  }

  Expression parseOr(TokenReader reader) {
    var expression = parseAnd(reader);

    while (reader.skipIf('name', 'or')) {
      expression = Or(expression, parseAnd(reader));
    }

    return expression;
  }

  Expression parseAnd(TokenReader reader) {
    var expression = parseNot(reader);

    while (reader.skipIf('name', 'and')) {
      expression = And(expression, parseNot(reader));
    }

    return expression;
  }

  Expression parseNot(TokenReader reader) {
    if (reader.current.test('name', 'not')) {
      reader.next();
      return Not(parseNot(reader));
    }

    return parseCompare(reader);
  }

  Expression parseCompare(TokenReader reader) {
    final expression = parseMath1(reader);
    final operands = <Operand>[];
    String type;

    while (true) {
      if (reader.current.testAny(['eq', 'ne', 'lt', 'lteq', 'gt', 'gteq'])) {
        type = reader.current.type;

        reader.next();

        operands.add(Operand(type, parseMath1(reader)));
      } else if (reader.skipIf('name', 'in')) {
        operands.add(Operand('in', parseMath1(reader)));
      } else if (reader.current.test('name', 'not') && reader.look().test('name', 'in')) {
        reader.skip(2);

        operands.add(Operand('notin', parseMath1(reader)));
      } else {
        break;
      }
    }

    if (operands.isEmpty) {
      return expression;
    }

    return Compare(expression, operands);
  }

  Expression parseMath1(TokenReader reader) {
    var expression = parseConcat(reader);

    outer:
    while (true) {
      switch (reader.current.type) {
        case 'add':
          reader.next();

          expression = Add(expression, parseConcat(reader));
          break;
        case 'sub':
          reader.next();

          expression = Sub(expression, parseConcat(reader));
          break;
        default:
          break outer;
      }
    }

    return expression;
  }

  Expression parseConcat(TokenReader reader) {
    final expressions = <Expression>[parseMath2(reader)];

    while (reader.current.test('tilde')) {
      reader.next();

      expressions.add(parseMath2(reader));
    }

    if (expressions.length == 1) {
      return expressions[0];
    }

    return Concat(expressions);
  }

  Expression parseMath2(TokenReader reader) {
    var expression = parsePow(reader);

    outer:
    while (true) {
      switch (reader.current.type) {
        case 'mul':
          reader.next();

          expression = Mul(expression, parsePow(reader));
          break;
        case 'div':
          reader.next();

          expression = Div(expression, parsePow(reader));
          break;
        case 'floordiv':
          reader.next();

          expression = FloorDiv(expression, parsePow(reader));
          break;
        case 'mod':
          reader.next();
          expression = Mod(expression, parsePow(reader));
          break;
        default:
          break outer;
      }
    }

    return expression;
  }

  Expression parsePow(TokenReader reader) {
    var expression = parseUnary(reader);

    while (reader.current.test('pow')) {
      reader.next();

      expression = Pow(expression, parseUnary(reader));
    }

    return expression;
  }

  Expression parseUnary(TokenReader reader, {bool withFilter = true}) {
    Expression expression;

    switch (reader.current.type) {
      case 'add':
        reader.next();

        expression = parseUnary(reader, withFilter: false);
        expression = Pos(expression);
        break;
      case 'sub':
        reader.next();

        expression = parseUnary(reader, withFilter: false);
        expression = Neg(expression);
        break;
      default:
        expression = parsePrimary(reader);
    }

    expression = parsePostfix(reader, expression);

    if (withFilter) {
      expression = parseFilterExpression(reader, expression);
    }

    return expression;
  }

  Expression parsePrimary(TokenReader reader) {
    Expression expression;

    switch (reader.current.type) {
      case 'name':
        switch (reader.current.value) {
          case 'False':
          case 'false':
            expression = Constant<bool>(false);
            break;
          case 'True':
          case 'true':
            expression = Constant<bool>(true);
            break;
          case 'None':
          case 'none':
            expression = Constant<Null>(null);
            break;
          default:
            expression = Name(reader.current.value);
        }

        reader.next();
        break;
      case 'string':
        final buffer = StringBuffer(reader.current.value);

        reader.next();

        while (reader.current.test('string')) {
          buffer.write(reader.current.value);

          reader.next();
        }

        expression = Constant<String>(buffer.toString());
        break;
      case 'integer':
        expression = Constant<int>(int.parse(reader.current.value));
        reader.next();

        break;
      case 'float':
        expression = Constant<double>(double.parse(reader.current.value));
        reader.next();

        break;
      case 'lparen':
        reader.next();

        expression = parseTuple(reader, explicitParentheses: true);

        reader.expect('rparen');
        break;
      case 'lbracket':
        expression = parseList(reader);
        break;
      case 'lbrace':
        expression = parseDict(reader);
        break;
      default:
        throw 'unexpected token: ${reader.current}';
    }

    return expression;
  }

  Expression parseTuple(TokenReader reader,
      {bool simplified = false, bool withCondition = true, List<String>? extraEndRules, bool explicitParentheses = false}) {
    Expression Function(TokenReader) parse;
    if (simplified) {
      parse = parsePrimary;
    } else if (withCondition) {
      parse = parseExpression;
    } else {
      parse = (reader) => parseExpression(reader, false);
    }

    final values = <Expression>[];
    var isTuple = false;

    while (true) {
      if (values.isNotEmpty) {
        reader.expect('comma');
      }

      if (isTupleEnd(reader, extraEndRules)) {
        break;
      }

      values.add(parse(reader));

      if (reader.current.test('comma')) {
        isTuple = true;
      } else {
        break;
      }
    }

    if (!isTuple) {
      if (values.isNotEmpty) {
        return values.first;
      }

      if (explicitParentheses) {
        throw 'expected an expression, got ${reader.current}';
      }
    }

    return TupleLiteral(values);
  }

  Expression parseList(TokenReader reader) {
    reader.expect('lbracket');

    final values = <Expression>[];

    while (!reader.current.test('rbracket')) {
      if (values.isNotEmpty) {
        reader.expect('comma');
      }

      if (reader.current.test('rbracket')) {
        break;
      }

      values.add(parseExpression(reader));
    }

    reader.expect('rbracket');

    return ListLiteral(values);
  }

  Expression parseDict(TokenReader reader) {
    reader.expect('lbrace');

    final pairs = <Pair>[];

    while (!reader.current.test('rbrace')) {
      if (pairs.isNotEmpty) {
        reader.expect('comma');
      }

      if (reader.current.test('rbrace')) {
        break;
      }

      final key = parseExpression(reader);

      reader.expect('colon');

      final value = parseExpression(reader);
      pairs.add(Pair(key, value));
    }

    reader.expect('rbrace');
    return DictLiteral(pairs);
  }

  Expression parsePostfix(TokenReader reader, Expression expression) {
    while (true) {
      if (reader.current.test('dot') || reader.current.test('lbracket')) {
        expression = parseSubscript(reader, expression);
      } else if (reader.current.test('lparen')) {
        expression = parseCall(reader, expression);
      } else {
        break;
      }
    }

    return expression;
  }

  Expression parseFilterExpression(TokenReader reader, Expression expression) {
    while (true) {
      if (reader.current.test('pipe')) {
        expression = parseFilter(reader, expression);
      } else if (reader.current.test('name', 'is')) {
        expression = parseTest(reader, expression);
      } else if (reader.current.test('lparen')) {
        expression = parseCall(reader, expression);
      } else {
        break;
      }
    }

    return expression;
  }

  Expression parseSubscript(TokenReader reader, Expression expression) {
    final token = reader.next();

    if (token.test('dot')) {
      final attributeToken = reader.next();

      if (attributeToken.test('name')) {
        return Attribute(attributeToken.value, expression);
      } else if (!attributeToken.test('integer')) {
        throw 'expected name or number';
      }

      return Item(Constant<int>(int.parse(attributeToken.value)), expression);
    } else if (token.test('lbracket')) {
      var arguments = <Expression>[];

      while (!reader.current.test('rbracket')) {
        if (arguments.isNotEmpty) {
          reader.expect('comma');
        }

        arguments.add(parseSubscribed(reader));
      }

      reader.expect('rbracket');

      arguments = arguments.reversed.toList();

      while (arguments.isNotEmpty) {
        expression = Item(arguments.removeLast(), expression);
      }

      return expression;
    }

    throw 'expected subscript expression';
  }

  Expression parseSubscribed(TokenReader reader) {
    final arguments = <Expression?>[];

    if (reader.current.test('colon')) {
      reader.next();

      arguments.add(null);
    } else {
      final expression = parseExpression(reader);

      if (!reader.current.test('colon')) {
        return expression;
      }

      reader.next();

      arguments.add(expression);
    }

    if (reader.current.test('colon')) {
      arguments.add(null);
    } else if (!reader.current.test('rbracket') && !reader.current.test('comma')) {
      arguments.add(parseExpression(reader));
    } else {
      arguments.add(null);
    }

    if (reader.current.test('colon')) {
      reader.next();

      if (!reader.current.test('rbracket') && !reader.current.test('comma')) {
        arguments.add(parseExpression(reader));
      } else {
        arguments.add(null);
      }
    } else {
      arguments.add(null);
    }

    return Slice.fromList(arguments);
  }

  Call parseCall(TokenReader reader, Expression expression) {
    reader.expect('lparen');

    final arguments = <Expression>[];
    final keywordArguments = <Keyword>[];
    Expression? dArguments, dKeywordArguments;

    var requireComma = false;

    void ensure(bool ensure) {
      if (!ensure) {
        throw 'invalid syntax for function call expression';
      }
    }

    while (!reader.current.test('rparen')) {
      if (requireComma) {
        reader.expect('comma');

        if (reader.current.test('rparen')) {
          break;
        }
      }

      if (reader.current.test('mul')) {
        ensure(dArguments == null && dKeywordArguments == null);

        reader.next();

        dArguments = parseExpression(reader);
      } else if (reader.current.test('pow')) {
        ensure(dKeywordArguments == null);

        reader.next();

        dArguments = parseExpression(reader);
      } else {
        if (reader.current.test('name') && reader.look().test('assign')) {
          final key = reader.current.value;

          reader.skip(2);

          final value = parseExpression(reader);
          keywordArguments.add(Keyword(key, value));
        } else {
          ensure(dArguments == null && dKeywordArguments == null && keywordArguments.isEmpty);
          arguments.add(parseExpression(reader));
        }
      }

      requireComma = true;
    }

    reader.expect('rparen');

    return Call(expression, arguments: arguments, keywordArguments: keywordArguments, dArguments: dArguments, dKeywordArguments: dKeywordArguments);
  }

  Expression parseFilter(TokenReader reader, Expression expression, [bool startInline = false]) {
    while (reader.current.test('pipe') || startInline) {
      if (!startInline) {
        reader.next();
      }

      var token = reader.expect('name');
      var name = token.value;

      while (reader.current.test('dot')) {
        reader.next();

        token = reader.expect('name');
        name = '$name.${token.value}';
      }

      Call call;

      if (reader.current.test('lparen')) {
        call = parseCall(reader, Constant<String>(''));
      } else {
        call = Call(Constant<String>(''));
      }

      expression = Filter.fromCall(name, expression, call);
      startInline = false;
    }

    return expression;
  }

  Expression parseTest(TokenReader reader, Expression expression) {
    reader.next();

    var negated = false;

    if (reader.current.test('name', 'not')) {
      reader.next();

      negated = true;
    }

    var token = reader.expect('name');
    var name = token.value;

    while (reader.current.test('dot')) {
      reader.next();

      token = reader.expect('name');
      name = '$name.${token.value}';
    }

    Call call;

    if (reader.current.test('lparen')) {
      call = parseCall(reader, Constant<String>(''));
    } else if (reader.current.testAny(['name', 'string', 'integer', 'float', 'lparen', 'lbracket', 'lbrace']) &&
        !reader.current.testAny(['name:else', 'name:or', 'name:and'])) {
      if (reader.current.test('name', 'is')) {
        throw 'you cannot chain multiple tests with is';
      }

      var argument = parsePrimary(reader);
      argument = parsePostfix(reader, argument);
      call = Call(Constant<String>(''), arguments: <Expression>[argument]);
    } else {
      call = Call(Constant<String>(''));
    }

    expression = Test.fromCall(name, expression, call);

    if (negated) {
      expression = Not(expression);
    }

    return expression;
  }

  @override
  String toString() {
    return 'Parser()';
  }
}

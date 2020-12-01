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

  bool isTupleEnd(TokenReader reader, [List<String> extraEndRules = const <String>[]]) {
    switch (reader.current.type) {
      case 'variable_end':
      case 'block_end':
      case 'rparen':
        return true;
      default:
        if (extraEndRules.isNotEmpty) {
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

  List<Node> subParse(TokenReader reader, {List<String> endRules = const <String>[]}) {
    final buffer = StringBuffer();
    final nodes = <Node>[];

    if (endRules.isNotEmpty) {
      endRulesStack.add(endRules);
    }

    void flush() {
      if (buffer.isNotEmpty) {
        nodes.add(Data(buffer.toString()));
        buffer.clear();
      }
    }

    try {
      while (!reader.current.test('eof')) {
        final token = reader.current;

        switch (token.type) {
          case 'data':
            buffer.write(token.value);
            reader.next();
            break;
          case 'variable_begin':
            flush();
            reader.next();
            nodes.add(parseTuple(reader, withCondExpr: true));
            reader.expect('variable_end');
            break;
          case 'block_begin':
            flush();
            reader.next();

            if (endRules.isNotEmpty && reader.current.testAny(endRules)) {
              return nodes;
            }

            nodes.add(parseStatement(reader));
            break;
          default:
            throw 'unexpected token: $token';
        }
      }

      flush();
    } finally {
      if (endRules.isNotEmpty) {
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

  List<Node> parseStatements(TokenReader reader, List<String> endRules, {bool dropNeedle = false}) {
    reader.skipIf('colon');
    reader.expect('blockEnd');

    final nodes = subParse(reader, endRules: endRules);

    if (reader.current.test('eof')) {
      throw 'unexpected end of file';
    }

    if (dropNeedle) {
      reader.next();
    }

    return nodes;
  }

  Node parseIf(TokenReader reader) {
    If result, node;
    result = node = If(Constant<bool>(true), <Node>[Data()], <Node>[], <Node>[]);

    while (true) {
      node.test = parseTuple(reader, withCondExpr: false);
      node.body = parseStatements(reader, <String>['name:elif', 'name:else', 'name:endif']);
      node.elseIf = <Node>[];
      node.$else = <Node>[];

      final token = reader.next();

      if (token.test('name', 'elif')) {
        node = If(Constant<bool>(true), <Node>[Data()], <Node>[], <Node>[]);
        result.elseIf.add(node);
        continue;
      } else if (token.test('name', 'else')) {
        result.elseIf = parseStatements(reader, <String>['name:endif']);
      } else {
        break;
      }
    }

    return result;
  }

  Expression parseExpression(TokenReader reader, [bool withCondExpr = true]) {
    return withCondExpr ? parseCondition(reader) : parseOr(reader);
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
      return Not(parseNot(reader));
    }

    return parseCompare(reader);
  }

  Expression parseCompare(TokenReader reader) {
    var expression = parseMath1(reader);
    var operands = <Operand>[];

    while (true) {
      if (reader.current.testAny(['eq', 'ne', 'lt', 'lteq', 'gt', 'gteq'])) {
        reader.next();
        operands.add(Operand(reader.current.type, parseMath1(reader)));
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
          expression = Add(expression, parseConcat(reader));
          break;
        case 'sub':
          expression = Sub(expression, parseConcat(reader));
          break;
        default:
          break outer;
      }
    }

    return expression;
  }

  Expression parseConcat(TokenReader reader) {
    var expressions = <Expression>[parseUnary(reader)];

    while (reader.current.test('tilde')) {
      reader.next();
      expressions.add(parseUnary(reader));
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
          expression = Mul(expression, parsePow(reader));
          break;
        case 'div':
          expression = Div(expression, parsePow(reader));
          break;
        case 'floorDiv':
          expression = FloorDiv(expression, parsePow(reader));
          break;
        case 'mod':
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
        expression = Positive(expression);
        break;
      case 'sub':
        reader.next();
        expression = parseUnary(reader, withFilter: false);
        expression = Negative(expression);
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
          case 'false':
            expression = Constant<bool>(false);
            break;
          case 'true':
            expression = Constant<bool>(true);
            break;
          case 'null':
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
        expression = parseTuple(reader);
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
      {bool simplified = false, bool withCondExpr = true, List<String> extraEndRules = const <String>[], bool explicitParentheses = false}) {
    Expression Function(TokenReader) parse;

    if (simplified) {
      parse = parsePrimary;
    } else if (withCondExpr) {
      parse = parseExpression;
    } else {
      parse = (reader) => parseExpression(reader, false);
    }

    var values = <Expression>[];
    var isTuple = false;

    while (true) {
      if (values.isNotEmpty) {
        reader.expect('comma');
      }

      if (isTupleEnd(reader, extraEndRules)) {
        break;
      }

      values.add(parse(reader));

      if (!isTuple && reader.current.test('comma')) {
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
    var values = <Expression>[];

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
    var pairs = <Pair>[];

    while (!reader.current.test('rbrace')) {
      if (pairs.isNotEmpty) {
        reader.expect('comma');
      }

      if (reader.current.test('rbrace')) {
        break;
      }

      var key = parseExpression(reader);
      reader.expect('colon');
      var value = parseExpression(reader);
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
    var token = reader.next();

    if (token.test('dot')) {
      var attributeToken = reader.next();

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
        var key = arguments.removeLast();

        if (key is Slice) {
          expression = Slice(expression, key.start, stop: key.stop, step: key.step);
        } else {
          expression = Item(key, expression);
        }
      }

      return expression;
    }

    throw 'expected subscript expression';
  }

  Expression parseSubscribed(TokenReader reader) {
    var arguments = <Expression?>[];

    if (reader.current.test('colon')) {
      reader.next();
      arguments.add(null);
    } else {
      var expression = parseExpression(reader);

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

    return Slice.fromList(Data(), arguments);
  }

  Call parseCall(TokenReader reader, Expression expression) {
    reader.expect('lparen');
    var arguments = <Expression>[];
    var keywordArguments = <Keyword>[];
    Expression? dArguments, dKeywordArguments;

    void ensure(bool ensure) {
      if (!ensure) {
        throw 'invalid syntax for function call expression';
      }
    }

    while (!reader.current.test('rparen')) {
      if (arguments.isNotEmpty || keywordArguments.isNotEmpty) {
        reader.expect('comma');

        if (reader.current.type == 'rparen') {
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
          var key = reader.current.value;
          reader.skip(2);
          var value = parseExpression(reader);
          keywordArguments.add(Keyword(key, value));
        } else {
          ensure(keywordArguments.isEmpty);
          arguments.add(parseExpression(reader));
        }
      }
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
        call = parseCall(reader, Data());
      } else {
        call = Call(Data());
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
      call = parseCall(reader, Data());
    } else if (reader.current.testAny(['name', 'string', 'integer', 'float', 'lparen', 'lbracket', 'lbrace']) &&
        !reader.current.testAny(['name:else', 'name:or', 'name:and'])) {
      if (reader.current.test('name', 'is')) {
        throw 'you cannot chain multiple tests with is';
      }

      // print('current: ${reader.current}');
      var argument = parsePrimary(reader);
      argument = parsePostfix(reader, argument);
      // print('current: ${reader.current}');
      call = Call(Data(), arguments: <Expression>[argument]);
    } else {
      call = Call(Data());
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

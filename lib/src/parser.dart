library parser;

import 'package:meta/meta.dart';

import 'nodes.dart';
import 'environment.dart';
import 'reader.dart';
import 'tokenizer.dart';

class Parser {
  Parser(this.environment)
      : endRulesStack = <List<String>>[],
        tagStack = <String>[];

  final Environment environment;

  final List<List<String>> endRulesStack;

  final List<String> tagStack;

  bool isTupleEnd(TokenReader reader, [List<String> extraEndRules]) {
    switch (reader.current.type) {
      case TokenType.variableEnd:
      case TokenType.blockEnd:
      case TokenType.rParen:
        return true;
      default:
        if (extraEndRules != null && extraEndRules.isNotEmpty) {
          return extraEndRules.any(reader.current.test);
        }

        return false;
    }
  }

  Node parse(String template, {String path}) {
    final tokens = Tokenizer(environment).tokenize(template, path: path);
    final reader = TokenReader(tokens);
    return scan(reader);
  }

  @protected
  Node scan(TokenReader reader) {
    final nodes = subParse(reader);
    return Output(items: nodes);
  }

  List<Node> subParse(TokenReader reader, {List<String> endRules}) {
    final buffer = StringBuffer();
    final nodes = <Node>[];

    if (endRules.isNotEmpty) {
      endRulesStack.add(endRules);
    }

    void flush() {
      if (buffer.isNotEmpty) {
        nodes.add(Data(data: buffer.toString()));
        buffer.clear();
      }
    }

    try {
      while (!reader.current.test(TokenType.eof)) {
        final token = reader.current;

        switch (token.type) {
          case TokenType.data:
            buffer.write(token.value);
            reader.next();
            break;
          case TokenType.variableBegin:
            flush();
            reader.next();
            nodes.add(parseTuple(reader, withCondExpr: true));
            reader.expect(TokenType.variableEnd);
            break;
          case TokenType.blockBegin:
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

    if (!token.test(TokenType.name)) {
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
    reader.skipIf(TokenType.colon);
    reader.expect(TokenType.blockEnd);

    final nodes = subParse(reader, endRules: endRules);

    if (reader.current.test(TokenType.eof)) {
      throw 'unexpected end of file';
    }

    if (dropNeedle) {
      reader.next();
    }

    return nodes;
  }

  Node parseIf(TokenReader reader) {
    If result, node;
    result = node = If();

    while (true) {
      node.test = parseTuple(reader, withCondExpr: false);
      node.body = parseStatements(reader, <String>['name:elif', 'name:else', 'name:endif']);
      node.elseIf = <Node>[];
      node.$else = <Node>[];

      final token = reader.next();

      if (token.test(TokenType.name, 'elif')) {
        node = If();
        result.elseIf.add(node);
        continue;
      } else if (token.test(TokenType.name, 'else')) {
        result.elseIf = parseStatements(reader, <String>['name:endif']);
      } else {
        break;
      }
    }

    return result;
  }

  Expression parseExpression(TokenReader reader, {bool withCondExpr = true}) {
    return parseUnary(reader);
  }

  Expression parseUnary(TokenReader reader, {bool withFilter = true}) {
    Expression expression;

    switch (reader.current.type) {
      case TokenType.sub:
        reader.next();
        expression = parseUnary(reader, withFilter: false);
        expression = Negative(expression: expression);
        break;
      case TokenType.add:
        reader.next();
        expression = parseUnary(reader, withFilter: false);
        expression = Positive(expression: expression);
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
    var token = reader.current;
    Expression expression;

    switch (token.type) {
      case TokenType.name:
        switch (token.value) {
          case 'false':
            expression = Constant<bool>(value: false);
            break;
          case 'true':
            expression = Constant<bool>(value: true);
            break;
          case 'null':
            expression = Constant<Null>(value: null);
            break;
          default:
            expression = Name(name: token.value);
        }

        reader.next();
        break;
      case TokenType.string:
        final buffer = StringBuffer(token.value);
        token = reader.next();

        while (token.test(TokenType.string)) {
          buffer.write(token.value);
          token = reader.next();
        }

        expression = Constant<String>(value: buffer.toString());
        break;
      case TokenType.integer:
        expression = Constant<int>(value: int.parse(token.value));
        reader.next();
        break;
      case TokenType.float:
        expression = Constant<double>(value: double.parse(token.value));
        reader.next();
        break;
      case TokenType.lParen:
        reader.next();
        expression = parseTuple(reader);
        reader.expect(TokenType.rParen);
        break;
      case TokenType.lBracket:
        expression = parseList(reader);
        break;
      case TokenType.lBrace:
        expression = parseDict(reader);
        break;
      default:
        throw 'unexpected token: $token';
    }

    return expression;
  }

  Expression parseTuple(TokenReader reader, {bool simplified = false, bool withCondExpr = true, List<String> extraEndRules, bool explicitParentheses = false}) {
    Expression Function(TokenReader) parse;

    if (simplified) {
      parse = parsePrimary;
    } else if (withCondExpr) {
      parse = parseExpression;
    } else {
      parse = (reader) => parseExpression(reader, withCondExpr: false);
    }

    var items = <Expression>[];
    var isTuple = false;

    while (true) {
      if (items.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      if (isTupleEnd(reader, extraEndRules)) {
        break;
      }

      items.add(parse(reader));

      if (!isTuple && reader.current.test(TokenType.comma)) {
        isTuple = true;
      } else {
        break;
      }
    }

    if (!isTuple) {
      if (items.isNotEmpty) {
        return items.first;
      }

      if (explicitParentheses) {
        throw 'expected an expression, got ${reader.current}';
      }
    }

    return TupleLiteral(items: items);
  }

  Expression parseList(TokenReader reader) {
    reader.expect(TokenType.lBracket);
    var items = <Expression>[];

    while (!reader.current.test(TokenType.rBracket)) {
      if (items.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      if (reader.current.test(TokenType.rBracket)) {
        break;
      }

      items.add(parseExpression(reader));
    }

    reader.expect(TokenType.rBracket);
    return ListLiteral(items: items);
  }

  Expression parseDict(TokenReader reader) {
    reader.expect(TokenType.lBrace);
    var items = <Pair>[];

    while (!reader.current.test(TokenType.rBrace)) {
      if (items.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      if (reader.current.test(TokenType.rBrace)) {
        break;
      }

      var key = parseExpression(reader);
      reader.expect(TokenType.colon);
      var value = parseExpression(reader);
      items.add(Pair(key: key, value: value));
    }

    reader.expect(TokenType.rBrace);
    return DictLiteral(items: items);
  }

  Expression parsePostfix(TokenReader reader, Expression expression) {
    while (true) {
      if (reader.current.test(TokenType.dot) || reader.current.test(TokenType.lBracket)) {
        expression = parseSubscript(reader, expression);
      } else if (reader.current.test(TokenType.lParen)) {
        expression = parseCall(reader, expression);
      } else {
        break;
      }
    }

    return expression;
  }

  Expression parseFilterExpression(TokenReader reader, Expression expression) {
    while (true) {
      if (reader.current.test(TokenType.pipe)) {
        expression = parseFilter(reader, expression);
      } else if (reader.current.test(TokenType.name, 'is')) {
        expression = parseTest(reader, expression);
      } else if (reader.current.test(TokenType.lParen)) {
        expression = parseCall(reader, expression);
      } else {
        break;
      }
    }

    return expression;
  }

  Expression parseSubscript(TokenReader reader, Expression expression) {
    var token = reader.next();

    if (token.test(TokenType.dot)) {
      var attributeToken = reader.next();

      if (attributeToken.test(TokenType.name)) {
        return Attribute(attribute: attributeToken.value, expression: expression);
      } else if (!attributeToken.test(TokenType.integer)) {
        throw 'expected name or number';
      }

      return Item(key: Constant<int>(value: int.parse(attributeToken.value)), expression: expression);
    } else if (token.test(TokenType.lBracket)) {
      var arguments = <Expression>[];

      while (!reader.current.test(TokenType.rBracket)) {
        if (arguments.isNotEmpty) {
          reader.expect(TokenType.comma);
        }

        arguments.add(parseSubscribed(reader));
      }

      reader.expect(TokenType.rBracket);
      arguments = arguments.reversed.toList();

      while (arguments.isNotEmpty) {
        var key = arguments.removeLast();

        if (key is Slice) {
          expression = Slice(expression: expression, start: key.start, stop: key.stop, step: key.step);
        } else {
          expression = Item(key: key, expression: expression);
        }
      }

      return expression;
    }

    throw 'expected subscript expression';
  }

  Expression parseSubscribed(TokenReader reader) {
    var arguments = <Expression>[];

    if (reader.current.test(TokenType.colon)) {
      reader.next();
      arguments.add(null);
    } else {
      var expression = parseExpression(reader);

      if (!reader.current.test(TokenType.colon)) {
        return expression;
      }

      reader.next();
      arguments.add(expression);
    }

    if (reader.current.test(TokenType.colon)) {
      arguments.add(null);
    } else if (!reader.current.test(TokenType.rBracket) && !reader.current.test(TokenType.colon)) {
      arguments.add(parseExpression(reader));
    } else {
      arguments.add(null);
    }

    if (reader.current.test(TokenType.colon)) {
      reader.next();

      if (!reader.current.test(TokenType.rBracket) && reader.current.test(TokenType.colon)) {
        arguments.add(parseExpression(reader));
      } else {
        arguments.add(null);
      }
    } else {
      arguments.add(null);
    }

    return Slice.fromList(arguments);
  }

  Expression parseCall(TokenReader reader, Expression expression) {
    reader.expect(TokenType.lParen);
    var arguments = <Expression>[];
    var keywordArguments = <Keyword>[];

    void ensure(bool ensure) {
      if (!ensure) {
        throw 'invalid syntax for function call expression';
      }
    }

    while (!reader.current.test(TokenType.rParen)) {
      if (arguments.isNotEmpty || keywordArguments.isNotEmpty) {
        reader.expect(TokenType.comma);

        if (reader.current.type == TokenType.rParen) {
          break;
        }
      } else {
        if (reader.current.test(TokenType.name) && reader.look().test(TokenType.assign)) {
          var key = reader.current.value;
          reader.skip(2);
          var value = parseExpression(reader);
          keywordArguments.add(Keyword(key: key, value: value));
        } else {
          ensure(keywordArguments.isEmpty);
          arguments.add(parseExpression(reader));
        }
      }
    }

    reader.expect(TokenType.rParen);
    return Call(expression: expression, arguments: arguments, keywordArguments: keywordArguments);
  }

  @override
  String toString() {
    return 'Parser()';
  }
}

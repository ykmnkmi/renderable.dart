library parser;

import 'package:meta/meta.dart';

import 'nodes.dart';
import 'environment.dart';
import 'reader.dart';
import 'tokenizer.dart';

@immutable
class Parser {
  Parser(this.environment)
      : endRulesStack = <List<String>>[],
        tagsStack = <String>[];

  final Environment environment;

  final List<List<String>> endRulesStack;

  final List<String> tagsStack;

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
    return parseBody(reader);
  }

  Node parseBody(TokenReader reader, [List<String> endRules = const <String>[]]) {
    final nodes = subParse(reader, endRules);
    return Output(nodes);
  }

  List<Node> subParse(TokenReader reader, List<String> endRules) {
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
      while (reader.current.type != TokenType.eof) {
        final token = reader.current;

        switch (token.type) {
          case TokenType.data:
            buffer.write(token.value);
            reader.moveNext();
            break;
          case TokenType.variableBegin:
            flush();
            reader.moveNext();
            nodes.add(parseTuple(reader, withCondExpr: true));
            reader.expect(TokenType.variableEnd);
            break;
          case TokenType.blockBegin:
            flush();
            reader.moveNext();

            if (endRules.isNotEmpty && endRules.any(reader.current.test)) {
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
    reader.skipIf(TokenType.whitespace);

    final tagToken = reader.expected(TokenType.name);
    final tag = tagToken.value;
    tagsStack.add(tag);

    var popTag = true;

    reader.skipIf(TokenType.whitespace);

    try {
      switch (tag) {
        case 'if':
          return parseIf(reader);
        default:
          popTag = false;
          tagsStack.removeLast();
          throw 'unknown tag: ${tag}';
      }
    } finally {
      if (popTag) {
        tagsStack.removeLast();
      }
    }
  }

  Node parseIf(TokenReader reader) {
    final pairs = <Test, Node>{};
    Node orElse;

    while (true) {
      if (reader.peek().test(TokenType.blockEnd)) {
        throw 'expect if statement body';
      }

      final conditionExpression = parseExpression(reader);

      Test condition;

      if (conditionExpression is Test) {
        condition = conditionExpression;
      } else {
        condition = Test('defined', conditionExpression);
      }

      reader.expected(TokenType.blockEnd);

      final body = parseBody(reader, <String>['name:else', 'name:elif']);

      final token = reader.next();

      if (token.test('name:else')) {
        reader.skipIf(TokenType.whitespace);
        reader.expected(TokenType.blockEnd);

        pairs[condition] = body;
        orElse = parseBody(reader, <String>['name:elif']);
      } else {
        pairs[condition] = body;
      }

      break;
    }

    reader.expected(TokenType.name);
    reader.skipIf(TokenType.whitespace);
    reader.expected(TokenType.blockEnd);

    return If(pairs, orElse);
  }

  Expression parseExpression(TokenReader reader, {bool withCondExpr = true}) {
    return parseUnary(reader);
  }

  Expression parseUnary(TokenReader reader, {bool withFilter = true}) {
    Expression expression;

    switch (reader.current.type) {
      case TokenType.sub:
        reader.moveNext();
        expression = parseUnary(reader, withFilter: false);
        expression = Negative(expression);
        break;
      case TokenType.add:
        reader.moveNext();
        expression = parseUnary(reader, withFilter: false);
        expression = Positive(expression);
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
    final token = reader.current;

    Expression expression;

    switch (token.type) {
      case TokenType.name:
        switch (token.value) {
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
            expression = Name(token.value);
        }

        reader.moveNext();
        break;
      case TokenType.string:
        final buffer = StringBuffer(token.value);
        reader.moveNext();

        while (reader.current.type == TokenType.string) {
          buffer.write(reader.current.value);
          reader.moveNext();
        }

        expression = Constant<String>(buffer.toString());
        break;
      case TokenType.integer:
        expression = Constant<int>(int.parse(token.value));
        reader.moveNext();
        break;
      case TokenType.float:
        expression = Constant<double>(double.parse(token.value));
        reader.moveNext();
        break;
      case TokenType.lParen:
        reader.moveNext();
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

    final items = <Expression>[];
    var isTuple = false;

    while (true) {
      if (items.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      if (isTupleEnd(reader, extraEndRules)) {
        break;
      }

      items.add(parse(reader));

      if (!isTuple && reader.current.type == TokenType.comma) {
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

    return TupleLiteral(items);
  }

  Expression parseList(TokenReader reader) {
    final items = <Expression>[];
    reader.expect(TokenType.lBracket);

    while (reader.current.type != TokenType.rBracket) {
      if (items.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      if (reader.current.type == TokenType.rBracket) {
        break;
      }

      items.add(parseExpression(reader));
    }

    reader.expect(TokenType.rBracket);
    return ListLiteral(items);
  }

  Expression parseDict(TokenReader reader) {
    final items = <Pair>[];
    reader.expect(TokenType.lBrace);

    while (reader.current.type != TokenType.rBrace) {
      if (items.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      if (reader.current.type == TokenType.rBrace) {
        break;
      }

      final key = parseExpression(reader);
      reader.expect(TokenType.colon);
      final value = parseExpression(reader);
      items.add(Pair(key, value));
    }

    reader.expect(TokenType.rBrace);
    return DictLiteral(items);
  }

  Expression parsePostfix(TokenReader reader, Expression expression) {
    while (true) {
      if (reader.current.type == TokenType.dot || reader.current.type == TokenType.lBracket) {
        expression = parseSubscript(reader, expression);
      } else if (reader.current.type == TokenType.lParen) {
        // expression = parseCall(reader, expression);
      } else {
        break;
      }
    }

    return expression;
  }

  Expression parseFilterExpression(TokenReader reader, Expression expression) {
    while (true) {
      if (reader.current.type == TokenType.pipe) {
        // expression = parseFilter(reader, expression);
      } else if (reader.current.type == TokenType.name && reader.current.value == 'is') {
        // expression = parseTest(reader, expression);
      } else if (reader.current.type == TokenType.lParen) {
        // expression = parseCall(reader, expression);
      } else {
        break;
      }
    }

    return expression;
  }

  Expression parseSubscript(TokenReader reader, Expression expression) {
    final token = reader.current;

    if (token.type == TokenType.dot) {
      final attributeToken = reader.next();

      if (attributeToken.type == TokenType.name) {
        return Attribute(attributeToken.value, expression);
      } else if (attributeToken.type != TokenType.integer) {
        throw 'expected name or number';
      }

      return Item(Constant<int>(int.parse(attributeToken.value)), expression);
    } else if (token.type == TokenType.lBracket) {
      var arguments = <Expression>[];

      while (reader.current.type != TokenType.rBracket) {
        if (arguments.isNotEmpty) {
          reader.expect(TokenType.comma);
        }

        arguments.add(parseSubscribed(reader));
      }

      reader.expect(TokenType.rBracket);
      arguments = arguments.reversed.toList();

      while (arguments.isNotEmpty) {
        final key = arguments.removeLast();

        if (key is Slice) {
          expression = Slice(expression, key.start, key.stop, key.step);
        } else {
          expression = Item(key, expression);
        }
      }

      return expression;
    }

    throw 'expected subscript expression';
  }

  Expression parseSubscribed(TokenReader reader) {
    reader.moveNext();

    final arguments = <Expression>[];

    if (reader.current.type == TokenType.colon) {
      reader.moveNext();
      arguments.add(null);
    } else {
      final expression = parseExpression(reader);

      if (reader.current.type != TokenType.colon) {
        return expression;
      }

      reader.moveNext();
      arguments.add(expression);
    }

    if (reader.current.type == TokenType.colon) {
      arguments.add(null);
    } else if (reader.current.type != TokenType.rBracket || reader.current.type != TokenType.colon) {
      arguments.add(parseExpression(reader));
    } else {
      arguments.add(null);
    }

    if (reader.current.type == TokenType.colon) {
      reader.moveNext();

      if (reader.current.type != TokenType.rBracket || reader.current.type != TokenType.colon) {
        arguments.add(parseExpression(reader));
      } else {
        arguments.add(null);
      }
    } else {
      arguments.add(null);
    }

    return Slice.fromList(null, arguments);
  }

  @override
  String toString() {
    return 'Parser()';
  }
}

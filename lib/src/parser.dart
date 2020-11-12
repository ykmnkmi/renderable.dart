library parser;

import 'package:meta/meta.dart';

import 'nodes.dart';
import 'environment.dart';
import 'exceptions.dart';
import 'reader.dart';
import 'tokenizer.dart';
import 'utils.dart';

@immutable
class ExpressionParser {
  @alwaysThrows
  static void fail(String message) {
    throw TemplateSyntaxError(message);
  }

  ExpressionParser(this.environment);

  final Environment environment;

  @protected
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

  Expression parse(String expression) {
    final tokens = ExpressionTokenizer(environment).tokenize(expression.trim());
    final reader = TokenReader(tokens);
    return scan(reader);
  }

  @protected
  Expression scan(TokenReader reader) {
    return parseRoot(reader);
  }

  Expression parseRoot(TokenReader reader, {bool withCondExpr = true}) {
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
        reader.expected(TokenType.rParen);
        break;
      case TokenType.lBracket:
        expression = parseList(reader);
        break;
      case TokenType.lBrace:
        expression = parseDict(reader);
        break;
      default:
        error('unexpected token: $token');
    }

    return expression;
  }

  Expression parseTuple(TokenReader reader, {bool simplified = false, bool withCondExpr = true, List<String> extraEndRules, bool explicitParentheses = false}) {
    Expression Function(TokenReader) parse;

    if (simplified) {
      parse = parsePrimary;
    } else if (withCondExpr) {
      parse = parseRoot;
    } else {
      parse = (reader) => parseRoot(reader, withCondExpr: false);
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
        error('expected an expression, got ${reader.current}');
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

      items.add(parseRoot(reader));
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

      final key = parseRoot(reader);
      reader.expect(TokenType.colon);
      final value = parseRoot(reader);
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
        expression = parseCall(reader, expression);
      } else {
        break;
      }
    }

    return expression;
  }

  Expression parseFilterExpression(TokenReader reader, Expression expression) {
    while (true) {
      if (reader.current.type == TokenType.pipe) {
        expression = parseFilter(reader, expression);
      } else if (reader.current.type == TokenType.name && reader.current.value == 'is') {
        expression = parseTest(reader, expression);
      } else if (reader.current.type == TokenType.lParen) {
        expression = parseCall(reader, expression);
      } else {
        break;
      }
    }

    return expression;
  }

  Expression parseSubscript(TokenReader reader, Expression expression) {
    final token = reader.current;
    print('parseSubscript: $token');

    if (token.type == TokenType.dot) {
      final attributeToken = reader.next();

      if (attributeToken.type == TokenType.name) {
        return Attribute(attributeToken.value, expression);
      } else if (attributeToken.type != TokenType.integer) {
        fail('expected name or number');
      }

      return Item(Constant<int>(int.parse(attributeToken.value)), expression);
    } else if (token.type == TokenType.lBracket) {
      final arguments = <Expression>[];

      while (reader.current.type != TokenType.rBracket) {
        if (arguments.isNotEmpty) {
          reader.expect(TokenType.comma);
        }

        arguments.add(parseSubscribed(reader));
      }

      reader.expect(TokenType.rBracket);

      if (arguments.length == 1) {
        return Item(arguments.first, expression);
      } else {
        return Item(TupleLiteral(arguments), expression);
      }
    }

    fail('expected subscript expression');
  }

  Expression parseSubscribed(TokenReader reader) {
    reader.moveNext();

    final arguments = <Expression>[];

    if (reader.current.type == TokenType.colon) {
      reader.moveNext();
      arguments.add(null);
    } else {
      final expression = parseRoot(reader);

      if (reader.current.type != TokenType.colon) {
        return expression;
      }

      reader.moveNext();
      arguments.add(expression);
    }

    if (reader.current.type == TokenType.colon) {
      arguments.add(null);
    } else if (reader.current.type != TokenType.rBracket || reader.current.type != TokenType.colon) {
      arguments.add(parseRoot(reader));
    } else {
      arguments.add(null);
    }

    if (reader.current.type == TokenType.colon) {
      reader.moveNext();

      if (reader.current.type != TokenType.rBracket || reader.current.type != TokenType.colon) {
        arguments.add(parseRoot(reader));
      } else {
        arguments.add(null);
      }
    } else {
      arguments.add(null);
    }

    return Slice.fromList(arguments);
  }

  @override
  String toString() {
    return 'ExpressionParser()';
  }
}

@immutable
class Parser {
  Parser(this.environment)
      : endRulesStack = <List<String>>[],
        tagsStack = <String>[];

  final Environment environment;

  final List<List<String>> endRulesStack;

  final List<String> tagsStack;

  Node parse(String template, {String path}) {
    final tokens = Tokenizer(environment).tokenize(template, path: path);
    return scan(tokens);
  }

  @protected
  Node scan(Iterable<Token> tokens) {
    final reader = TokenReader(tokens);
    return parseBody(reader);
  }

  Node parseBody(TokenReader reader, [List<String> endRules]) {
    final nodes = subParse(reader, endRules);
    return Node.orList(nodes);
  }

  List<Node> subParse(TokenReader reader, List<String> endRules) {
    final buffer = StringBuffer();
    final nodes = <Node>[];

    if (endRules.isNotEmpty) {
      endRulesStack.add(endRules);
    }

    final void Function() flush = () {
      if (buffer.isNotEmpty) {
        nodes.add(Text(buffer.toString()));
        buffer.clear();
      }
    };

    try {
      while (reader.moveNext()) {
        final token = reader.current;

        switch (token.type) {
          case TokenType.text:
            buffer.write(token.value);

            break;

          case TokenType.commentBegin:
            flush();

            skipComment(reader);

            break;

          case TokenType.variableBegin:
            flush();

            final expression = parseExpression(reader);
            nodes.add(expression);

            reader.expected(TokenType.variableEnd);

            break;

          case TokenType.blockBegin:
            flush();

            reader.skip(TokenType.whiteSpace);

            if (endRules.isNotEmpty && testAll(reader, endRules)) {
              return nodes;
            }

            nodes.add(parseStatement(reader));

            break;

          default:
            throw Exception('unexpected token: $token, ${reader.next()}');
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

  void skipComment(TokenReader reader) {
    reader.skip(TokenType.comment);
    reader.expected(TokenType.commentEnd);
  }

  Expression parseExpression(TokenReader reader) {
    return ExpressionParser(environment).scan(reader);
  }

  Node parseStatement(TokenReader reader) {
    reader.skip(TokenType.whiteSpace);

    final tagToken = reader.expected(TokenType.name);
    final tag = tagToken.value;
    tagsStack.add(tag);

    var popTag = true;

    reader.skip(TokenType.whiteSpace);

    try {
      switch (tag) {
        case 'if':
          return parseIf(reader);
        default:
          popTag = false;
          tagsStack.removeLast();
          error('unknown tag: ${tag}');
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
        error('expect if statement body');
      }

      final conditionExpression = ExpressionParser(environment).scan(reader);

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
        reader.skip(TokenType.whiteSpace);
        reader.expected(TokenType.blockEnd);

        pairs[condition] = body;
        orElse = parseBody(reader, <String>['name:elif']);
      } else {
        pairs[condition] = body;
      }

      break;
    }

    reader.expected(TokenType.name);
    reader.skip(TokenType.whiteSpace);
    reader.expected(TokenType.blockEnd);

    return If(pairs, orElse);
  }

  bool testAll(TokenReader reader, List<String> endRules) {
    final current = reader.peek();

    for (final rule in endRules) {
      if (current.test(rule)) {
        return true;
      }
    }

    return false;
  }

  @override
  String toString() {
    return 'Parser()';
  }
}

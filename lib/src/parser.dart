library parser;

import 'package:meta/meta.dart';

import 'ast.dart';
import 'environment.dart';
import 'tokenizer.dart';

@alwaysThrows
void error(String message) {
  // TODO: wrap exception
  throw Exception(message);
}

@immutable
class ExpressionParser {
  ExpressionParser(this.environment);

  final Environment environment;

  Expression parse(String expression) {
    final tokens = ExpressionTokenizer(environment).tokenize(expression.trim());
    final reader = TokenReader(tokens);
    return scan(reader);
  }

  @protected
  Expression scan(TokenReader reader) {
    while (reader.moveNext()) {
      return root(reader);
    }
  }

  Expression root(TokenReader reader, {bool withCondExpr = true}) {
    return primary(reader);
  }

  Expression primary(TokenReader reader) {
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
        expression = tuple(reader);
        reader.expected(TokenType.rParen);
        break;
      case TokenType.lBracket:
        expression = list(reader);
        break;
      case TokenType.lBrace:
        expression = dict(reader);
        break;
      default:
        error('unexpected token: $token');
    }

    return expression;
  }

  Expression tuple(TokenReader reader, {bool simplified = false, bool withCondExpr = true, List<Token> extraEndRules, bool explicitParentheses = false}) {
    Expression Function(TokenReader) parse;

    if (simplified) {
      parse = primary;
    } else if (withCondExpr) {
      parse = root;
    } else {
      parse = (reader) => root(reader, withCondExpr: false);
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

  Expression list(TokenReader reader) {
    final items = <Expression>[];
    reader.expect(TokenType.lBracket);

    while (reader.current.type != TokenType.rBracket) {
      if (items.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      if (reader.current.type == TokenType.rBracket) {
        break;
      }

      items.add(root(reader));
    }

    reader.expect(TokenType.rBracket);
    return ListLiteral(items);
  }

  Expression dict(TokenReader reader) {
    final items = <Pair>[];
    reader.expect(TokenType.lBrace);

    while (reader.current.type != TokenType.rBrace) {
      if (items.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      if (reader.current.type == TokenType.rBrace) {
        break;
      }

      final key = root(reader);
      reader.expect(TokenType.colon);
      final value = root(reader);
      items.add(Pair(key, value));
    }

    reader.expect(TokenType.rBrace);
    return DictLiteral(items);
  }

  bool isTupleEnd(TokenReader reader, [List<Token> extraEndRules]) {
    switch (reader.current.type) {
      case TokenType.variableEnd:
      case TokenType.blockEnd:
      case TokenType.rParen:
        return true;
      default:
        if (extraEndRules != null && extraEndRules.isNotEmpty) {
          return extraEndRules.any((rule) => reader.current.same(rule));
        }

        return false;
    }
  }

  @override
  String toString() {
    return 'ExpressionParser()';
  }
}

@immutable
class Parser {
  Parser(this.environment)
      : endTokensStack = <List<Token>>[],
        tagsStack = <String>[];

  final Environment environment;

  final List<List<Token>> endTokensStack;

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

  Node parseBody(TokenReader reader, [List<Token> endTokens]) {
    final nodes = subParse(reader, endTokens ?? const <Token>[]);
    return Node.orList(nodes);
  }

  List<Node> subParse(TokenReader reader, List<Token> endTokens) {
    final buffer = StringBuffer();
    final nodes = <Node>[];

    if (endTokens.isNotEmpty) {
      endTokensStack.add(endTokens);
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

            if (endTokens.isNotEmpty && testAll(reader, endTokens)) {
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
      if (endTokens.isNotEmpty) {
        endTokensStack.removeLast();
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
    const elseToken = Token(0, TokenType.name, 'else');
    const endIfToken = Token(0, TokenType.name, 'endif');

    final pairs = <Test, Node>{};
    Node orElse;

    while (true) {
      if (reader.isNext(TokenType.blockEnd)) {
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

      final body = parseBody(reader, <Token>[elseToken, endIfToken]);

      final token = reader.next();

      if (token.same(elseToken)) {
        reader.skip(TokenType.whiteSpace);
        reader.expected(TokenType.blockEnd);

        pairs[condition] = body;
        orElse = parseBody(reader, <Token>[endIfToken]);
      } else {
        pairs[condition] = body;
      }

      break;
    }

    reader.expected(TokenType.name);
    reader.skip(TokenType.whiteSpace);
    reader.expected(TokenType.blockEnd);

    return IfStatement(pairs, orElse);
  }

  bool testAll(TokenReader reader, List<Token> endTokens) {
    final current = reader.peek();

    for (final endToken in endTokens) {
      if (endToken.same(current)) {
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

class TokenReader {
  TokenReader(Iterable<Token> tokens) : _iterator = tokens.iterator;

  final Iterator<Token> _iterator;

  Token _peek;

  Token get current {
    return _iterator.current;
  }

  bool isNext(TokenType type) {
    _peek = next();
    return _peek == null ? false : _peek.type == type;
  }

  bool moveNext() {
    if (_peek != null) {
      _peek = null;
      return true;
    }

    return _iterator.moveNext();
  }

  Token next() {
    if (_peek != null) {
      final token = _peek;
      _peek = null;
      return token;
    }

    return _iterator.moveNext() ? _iterator.current : null;
  }

  Token peek() {
    return _peek = next();
  }

  bool skip(TokenType type, [bool all = false]) {
    if (peek()?.type == type) {
      next();

      if (all) {
        skip(type, all);
      }

      return true;
    }

    return false;
  }

  Token expect(TokenType type) {
    if (this.current == null || this.current.type != type) {
      error('expected token $type, got ${this.current}');
    }

    final current = this.current;
    moveNext();
    return current;
  }

  Token expected(TokenType type) {
    final token = next();

    if (token == null || token.type != type) {
      error('expected token $type, got $token');
    }

    return token;
  }
}

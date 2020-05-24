library parser;

import 'package:meta/meta.dart';

import 'ast.dart';
import 'environment.dart';
import 'tokenizer.dart';

@immutable
class ExpressionParser {
  final Environment environment;

  const ExpressionParser(this.environment);

  Node parse(String expression) {
    return scan(TokenReader(ExpressionTokenizer(environment).tokenize(expression)));
  }

  @protected
  Node scan(TokenReader reader) {
    final peek = reader.peek();

    if (peek == null || peek.type == TokenType.expressionEnd) {
      error('interpolation body expected.');
    }

    reader.skip(TokenType.space);

    final token = reader.next();
    Node node;

    if (token != null) {
      switch (token.type) {
        case TokenType.identifier:
          node = Variable(token.lexeme);
          break;
        default:
          error('unexpected token: $token.');
      }
    } else {
      error('expected tokens');
    }

    reader.skip(TokenType.space);
    reader.expected(TokenType.expressionEnd);

    return node;
  }

  @override
  String toString() {
    return 'ExpressionParser ()';
  }

  @alwaysThrows
  static void error(String message) {
    throw Exception(message);
  }
}

@immutable
class Parser {
  final Environment environment;

  const Parser(this.environment);

  Iterable<Node> parse(String template, {String path}) {
    return scan(Tokenizer(environment).tokenize(template, path: path));
  }

  @protected
  Iterable<Node> scan(Iterable<Token> tokens) sync* {
    final reader = TokenReader(tokens);
    final expressionParser = ExpressionParser(environment);

    var token = reader.next();

    while (token != null) {
      switch (token.type) {
        case TokenType.commentStart:
          skipComment(reader);
          break;
        case TokenType.expressionStart:
          yield expressionParser.scan(reader);
          break;
        case TokenType.statementStart:
          yield scanStatement(reader);
          break;
        case TokenType.text:
          yield Text(token.lexeme);
          break;
        default:
          error('unexpected token: $token.');
      }

      token = reader.next();
    }
  }

  Node scanStatement(TokenReader reader) {
    reader.skip(TokenType.space);
    
    final tag = reader.expected(TokenType.identifier);
    throw tag;
  }

  void skipComment(TokenReader reader) {
    reader.skip(TokenType.comment);
    reader.expected(TokenType.commentEnd);
  }

  @override
  String toString() {
    return 'Parser ()';
  }

  @alwaysThrows
  static void error(String message) {
    throw Exception(message);
  }
}

class TokenReader {
  final Iterator<Token> iterator;

  Token _peek;

  TokenReader(Iterable<Token> tokens) : iterator = tokens.iterator;

  Token expected(TokenType type) {
    final token = next();

    if (token == null || token.type != type) {
      throw Exception('$type token expected, got ${token.type}.');
    }

    return token;
  }

  Token next() {
    if (_peek != null) {
      final token = _peek;
      _peek = null;
      return token;
    }

    return iterator.moveNext() ? iterator.current : null;
  }

  Token peek() {
    return _peek = next();
  }

  bool skip(TokenType type) {
    if (peek()?.type == type) {
      next();
      return true;
    }

    return false;
  }
}

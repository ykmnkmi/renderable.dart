library parser;

import 'package:meta/meta.dart';

import 'ast.dart';
import 'tokenizer.dart';

class TokenReader {
  TokenReader(Iterable<Token> tokens) : iterator = tokens.iterator;

  final Iterator<Token> iterator;

  Token _peek;

  Token next() {
    if (_peek != null) {
      Token token = _peek;
      _peek = null;
      return token;
    }

    return iterator.moveNext() ? iterator.current : null;
  }

  Token peek() => _peek = next();

  bool skip(TokenType type) {
    if (peek().type == type) {
      next();
      return true;
    }

    return false;
  }

  Token expected(TokenType type) {
    final Token token = next();

    if (token == null || token.type != type) {
      throw Exception('$type token expected, got ${token.type}.');
    }

    return token;
  }
}

class Parser {
  @literal
  const Parser();

  Iterable<Node> parse(String template, {String path}) => scan(const Tokenizer().tokenize(template, path: path));

  @protected
  Iterable<Node> scan(Iterable<Token> tokens) sync* {
    TokenReader reader = TokenReader(tokens);
    ExpressionParser expressionParser = ExpressionParser();
    Token token;

    while ((token = reader.next()) != null) {
      switch (token.type) {
        case TokenType.commentStart:
          comment(reader);
          break;
        case TokenType.expressionStart:
          yield expressionParser.scan(reader);
          break;
        case TokenType.text:
          yield Text(token.lexeme);
          break;
        default:
          error('unexpected token: $token.');
      }
    }
  }

  void comment(TokenReader reader) {
    reader.skip(TokenType.comment);
    reader.expected(TokenType.commentEnd);
  }

  @alwaysThrows
  void error(String message) {
    throw Exception(message);
  }

  @override
  String toString() => 'Parser()';
}

class ExpressionParser {
  Node parse(String expression) => scan(TokenReader(ExpressionTokenizer().tokenize(expression)));

  @protected
  Node scan(TokenReader reader) {
    Token peek = reader.peek();

    if (peek == null || peek.type == TokenType.expressionEnd) {
      error('interpolation body expected.');
    }

    Node root = this.root(reader);
    reader.expected(TokenType.expressionEnd);
    return root;
  }

  Node root(TokenReader scanner) {
    scanner.skip(TokenType.space);

    Token token = scanner.next();
    Node node;

    switch (token.type) {
      case TokenType.identifier:
        node = Variable(token.lexeme);
        break;
      default:
        error('unexpected token: $token.');
    }

    scanner.skip(TokenType.space);

    return node;
  }

  @alwaysThrows
  void error(String message) {
    throw Exception(message);
  }

  @override
  String toString() => 'ExpressionParser()';
}

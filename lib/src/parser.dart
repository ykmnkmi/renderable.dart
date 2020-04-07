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

  List<Node> parse(String source) {
    final Iterable<Token> tokens = const Tokenizer().tokenize(source);
    final TokenReader reader = TokenReader(tokens);
    final List<Node> nodes = <Node>[];

    Token token;

    while ((token = reader.next()) != null) {
      switch (token.type) {
        case TokenType.commentStart:
          comment(reader);
          break;
        case TokenType.expressionStart:
          nodes.add(interpolation(reader));
          break;
        case TokenType.text:
          nodes.add(Text(token.lexeme));
          break;
        default:
          error('unexpected token: $token.');
      }
    }

    return nodes;
  }

  void comment(TokenReader scanner) {
    scanner.skip(TokenType.comment);
    scanner.expected(TokenType.commentEnd);
  }

  Node interpolation(TokenReader scanner) {
    final Token peek = scanner.peek();

    if (peek == null || peek.type == TokenType.expressionEnd) {
      error('interpolation body expected.');
    }

    final Node body = expression(scanner);
    scanner.expected(TokenType.expressionEnd);
    return body;
  }

  Node expression(TokenReader scanner) {
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
  String toString() => 'Parser()';
}

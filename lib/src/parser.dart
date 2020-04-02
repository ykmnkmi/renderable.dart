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

  bool skip(TokenType comment) {
    if (peek().type == comment) {
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
          skipComment(reader);
          break;
        case TokenType.expressionStart:
          nodes.add(parseInterpolation(reader));
          break;
        case TokenType.text:
          nodes.add(Text(token.lexeme));
          break;
        default:
          throw Exception('unexpected token: $token.');
      }
    }

    return nodes;
  }

  void skipComment(TokenReader scanner) {
    scanner.skip(TokenType.comment);
    scanner.expected(TokenType.commentEnd);
  }

  Node parseInterpolation(TokenReader scanner) {
    final Token peek = scanner.peek();

    if (peek == null || peek.type == TokenType.expressionEnd) {
      throw Exception('interpolation body expected.');
    }

    final Node body = parseExpression(scanner);
    scanner.expected(TokenType.expressionEnd);
    return body;
  }

  Node parseExpression(TokenReader scanner) {
    Token token = scanner.next();

    switch (token.type) {
      case TokenType.identifier:
        return Variable(token.lexeme);
      default:
        throw Exception('unexpected token: $token.');
    }
  }
}

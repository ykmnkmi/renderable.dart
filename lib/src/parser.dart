library parser;

import 'package:meta/meta.dart';

import 'ast.dart';
import 'tokenizer.dart';

class Scanner {
  Scanner(Iterable<Token> tokens) : iterator = tokens.iterator;

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
    final Iterable<Token> tokens = Tokenizer().tokenize(source);
    final Scanner scanner = Scanner(tokens);
    final List<Node> nodes = <Node>[];

    Token token;

    while ((token = scanner.next()) != null) {
      switch (token.type) {
        case TokenType.commentStart:
          skipComment(scanner);
          break;
        case TokenType.interpolationStart:
          nodes.add(parseInterpolation(scanner));
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

  void skipComment(Scanner scanner) {
    scanner.skip(TokenType.comment);
    scanner.expected(TokenType.commentEnd);
  }

  Node parseInterpolation(Scanner scanner) {
    final Token peek = scanner.peek();

    if (peek == null || peek.type == TokenType.interpolationEnd) {
      throw Exception('interpolation body expected.');
    }

    final Node body = parseExpression(scanner);
    scanner.expected(TokenType.interpolationEnd);
    return body;
  }

  Node parseExpression(Scanner scanner) {
    Token token = scanner.next();

    switch (token.type) {
      case TokenType.identifier:
        return Variable(token.lexeme);
      default:
        throw Exception('unexpected token: $token.');
    }
  }
}

library parser;

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

  Token peek() {
    return _peek = next();
  }
}

class Parser {
  static Parser _instance;

  static Parser Function() _factory = () {
    _instance = Parser._();
    _factory = () => _instance;
    return _instance;
  };

  factory Parser() {
    return _factory();
  }

  Parser._();

  List<Node> parse(String source) {
    final Iterable<Token> tokens = Tokenizer().tokenize(source);
    final Scanner scanner = Scanner(tokens);

    final List<Node> nodes = <Node>[];
    Token token;

    while ((token = scanner.next()) != null) {
      switch (token.type) {
        case TokenType.text:
          nodes.add(Text(token.lexeme));
          break;
        // case TokenType.commentStart:
        //   if (scanner.next())
        //   break;
        default:
          return null;
      }
    }

    return nodes;
  }

  Text parseText(Token token) {
    return Text(token.lexeme);
  }
}

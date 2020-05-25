library parser;

import 'package:meta/meta.dart';

import 'ast.dart';
import 'environment.dart';
import 'tokenizer.dart';

@immutable
class ExpressionParser {
  final Environment environment;

  const ExpressionParser(this.environment);

  Expression parse(String expression) {
    final tokens = ExpressionTokenizer(environment).tokenize(expression);
    final reader = TokenReader(tokens);
    return scan(reader);
  }

  @protected
  Expression scan(TokenReader reader) {
    reader.skip(TokenType.space);

    final token = reader.next();
    Expression node;

    if (token != null) {
      switch (token.type) {
        case TokenType.identifier:
          node = Variable(token.value);
          break;
        default:
          error('unexpected token: $token.');
      }
    } else {
      error('expected tokens');
    }

    reader.skip(TokenType.space);

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

  final List<List<Token>> endTokensStack;

  final List<String> tagsStack;

  Parser(this.environment)
      : endTokensStack = <List<Token>>[],
        tagsStack = <String>[];

  Iterable<Node> parse(String template, {String path}) {
    final tokens = Tokenizer(environment).tokenize(template, path: path);
    return scan(tokens);
  }

  Iterable<Node> parseBody(TokenReader reader, [List<Token> endTokens]) {
    final nodes = subParse(reader, endTokens ?? const <Token>[]);
    return nodes;
  }

  Node parseIf(TokenReader reader) {
    const elseToken = Token(0, 'else', TokenType.identifier);
    const endIfToken = Token(0, 'endif', TokenType.identifier);

    final pairs = <Expression, List<Node>>{};
    List<Node> orElse;

    while (true) {
      if (reader.isNext(TokenType.statementEnd)) {
        error('expect if statement body');
      }

      final condition = ExpressionParser(environment).scan(reader);
      reader.expected(TokenType.statementEnd);

      final body = parseBody(reader, <Token>[elseToken, endIfToken]).toList();

      final token = reader.next();

      if (token.same(elseToken)) {
        reader.skip(TokenType.space);
        reader.expected(TokenType.statementEnd);

        pairs[condition] = body;
        orElse = parseBody(reader, <Token>[endIfToken]).toList();
      } else {
        pairs[condition] = body;
      }

      break;
    }

    reader.expected(TokenType.identifier);
    reader.skip(TokenType.space);
    reader.expected(TokenType.statementEnd);

    return IfStatement(pairs, orElse);
  }

  Node parseStatement(TokenReader reader) {
    reader.skip(TokenType.space);

    final tagToken = reader.expected(TokenType.identifier);
    final tag = tagToken.value;
    tagsStack.add(tag);

    var popTag = true;

    reader.skip(TokenType.space);

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

  @protected
  Iterable<Node> scan(Iterable<Token> tokens) {
    final reader = TokenReader(tokens);
    return parseBody(reader);
  }

  void skipComment(TokenReader reader) {
    reader.skip(TokenType.comment);
    reader.expected(TokenType.commentEnd);
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

          case TokenType.commentStart:
            flush();

            skipComment(reader);

            break;

          case TokenType.expressionStart:
            flush();

            final expression = ExpressionParser(environment).scan(reader);
            nodes.add(expression);

            reader.expected(TokenType.expressionEnd);

            break;

          case TokenType.statementStart:
            flush();

            reader.skip(TokenType.space);

            if (endTokens.isNotEmpty && testAll(reader, endTokens)) {
              return nodes;
            }

            nodes.add(parseStatement(reader));

            break;

          default:
            throw Exception('unexpected token: $token, ${reader.next()}');
        }
      }
    } finally {
      if (endTokens.isNotEmpty) {
        endTokensStack.removeLast();
      }
    }

    return nodes;
  }

  bool testAll(TokenReader reader, List<Token> endTokens) {
    final current = reader.peek();

    for (final token in endTokens) {
      if (token.same(current)) {
        return true;
      }
    }

    return false;
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

  Token get current => iterator.current;

  Token expected(TokenType type) {
    final token = next();

    if (token == null || token.type != type) {
      throw Exception('$type token expected, got ${token.type}.');
    }

    return token;
  }

  bool moveNext() {
    return iterator.moveNext();
  }

  Token next() {
    if (_peek != null) {
      final token = _peek;
      _peek = null;
      return token;
    }

    return iterator.moveNext() ? iterator.current : null;
  }

  bool isNext(TokenType type) {
    _peek = next();
    return _peek.type == type;
  }

  Token peek() {
    return _peek = next();
  }

  bool skip(TokenType type, [bool all = false]) {
    if (peek()?.type == type) {
      next();

      if (all) {
        skip(type);
      }

      return true;
    }

    return false;
  }
}

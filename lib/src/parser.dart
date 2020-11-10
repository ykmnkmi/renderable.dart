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

  Expression root(TokenReader reader) {
    return primary(reader);
  }

  Expression primary(TokenReader reader) {
    final token = reader.current;

    switch (token.type) {
      case TokenType.name:
        if (token.value == 'false') return Literal<bool>(false);
        if (token.value == 'true') return Literal<bool>(true);
        if (token.value == 'null') return Literal<Null>(null);
        return Variable(token.value);
      case TokenType.string:
        final buffer = StringBuffer(token.value);

        while (reader.isNext(TokenType.string)) {
          buffer.write(reader.next().value);
        }

        return Literal<String>(buffer.toString());
      case TokenType.integer:
        return Literal<int>(int.parse(token.value));
      case TokenType.float:
        return Literal<double>(double.parse(token.value));
      case TokenType.lParen:
        reader.moveNext();
        return tuple(reader);
      default:
        error('unexpected token: $token');
    }
  }

  Expression tuple(TokenReader reader, {List<Token> extraEndRules, bool explicitParentheses = false}) {
    final args = <Expression>[];
    var isTuple = false;

    do {
      if (args.isNotEmpty) {
        reader.expected(TokenType.comma);
      }

      if (isTupleEnd(reader, extraEndRules)) {
        break;
      }

      args.add(root(reader));

      if (!isTuple && reader.current.type == TokenType.comma) {
        isTuple = true;
      } else {
        break;
      }
    } while (reader.next() != null);

    if (!isTuple) {
      if (args.isNotEmpty) {
        return args.first;
      }

      if (explicitParentheses) {
        error('expected an expression, got ${reader.current}');
      }
    }
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

            reader.skip(TokenType.whitespace);

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
    reader.skip(TokenType.whitespace);

    final tagToken = reader.expected(TokenType.name);
    final tag = tagToken.value;
    tagsStack.add(tag);

    var popTag = true;

    reader.skip(TokenType.whitespace);

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
        reader.skip(TokenType.whitespace);
        reader.expected(TokenType.blockEnd);

        pairs[condition] = body;
        orElse = parseBody(reader, <Token>[endIfToken]);
      } else {
        pairs[condition] = body;
      }

      break;
    }

    reader.expected(TokenType.name);
    reader.skip(TokenType.whitespace);
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
  TokenReader(Iterable<Token> tokens) : iterator = tokens.iterator;

  final Iterator<Token> iterator;

  Token _peek;

  Token get current {
    return iterator.current;
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

  Token expected(TokenType type) {
    final token = next();

    if (token == null || token.type != type) {
      throw Exception('$type token expected, got ${token.type}.');
    }

    return token;
  }
}

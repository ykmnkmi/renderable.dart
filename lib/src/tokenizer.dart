library tokenizer;

import 'package:meta/meta.dart';
import 'package:string_scanner/string_scanner.dart';

part 'token.dart';

class ExpressionTokenizer {
  final Pattern identifier;

  final Pattern space;
  
  ExpressionTokenizer()
      : identifier = RegExp('[a-zA-Z][a-zA-Z0-9]*'),
        space = RegExp(r'\s+');

  @alwaysThrows
  void error(StringScanner scanner, String message) {
    throw Exception('at ${scanner.position}: $message');
  }

  @protected
  Iterable<Token> scan(StringScanner scanner, {Pattern end = Tokenizer.expressionEnd}) sync* {
    while (!scanner.isDone) {
      if (scanner.scan(identifier)) {
        yield Token(scanner.lastMatch.start, scanner.lastMatch[0], TokenType.identifier);
      } else if (scanner.scan(space)) {
        yield Token.simple(scanner.lastMatch.start, TokenType.space);
      } else if (scanner.matches(end)) {
        return;
      } else {
        break;
      }
    }
  }

  Iterable<Token> tokenize(String expression) => scan(StringScanner(expression));

  @override
  String toString() => 'ExpressionTokenizer()';
}

class Tokenizer {
  static const Pattern commentStart = '{#';
  
  static const Pattern commentEnd = '#}';
  
  static const Pattern expressionStart = '{{';
  
  static const Pattern expressionEnd = '}}';
  
  static const Pattern statementStart = '{%';
  
  static const Pattern statementEnd = '%}';

  const Tokenizer();

  @alwaysThrows
  void error(StringScanner scanner, String message) {
    throw Exception('at ${scanner.position}: $message');
  }

  @protected
  Iterable<Token> scan(StringScanner scanner) sync* {
    ExpressionTokenizer expressionTokenizer = ExpressionTokenizer();

    while (!scanner.isDone) {
      int start = scanner.position;
      int end = start;

      String text;

      while (!scanner.isDone) {
        if (scanner.scan(commentStart)) {
          if (start < end) {
            text = scanner.substring(start, end);
            yield Token(start, text, TokenType.text);
          }

          yield Token.simple(scanner.lastMatch.start, TokenType.commentStart);

          start = scanner.lastMatch.end;
          end = start;

          while (!(scanner.isDone || scanner.matches(commentEnd))) {
            scanner.position++;
          }

          end = scanner.position;
          text = scanner.substring(start, end).trim();

          if (text.isEmpty) {
            error(scanner, 'expected comment body.');
          }

          if (!scanner.scan(commentEnd)) {
            error(scanner, 'expected comment end.');
          }

          yield Token(start, text, TokenType.comment);
          yield Token.simple(scanner.lastMatch.start, TokenType.commentEnd);
          start = scanner.lastMatch.end;
          end = start;
        }

        if (scanner.scan(expressionStart)) {
          text = scanner.substring(start, end);

          if (text.isNotEmpty) {
            yield Token(start, text, TokenType.text);
          }

          yield Token.simple(end, TokenType.expressionStart);
          yield* expressionTokenizer.scan(scanner);

          if (!scanner.scan(expressionEnd)) {
            error(scanner, 'expected expression end.');
          }

          end = scanner.lastMatch.start;
          start = end;

          yield Token.simple(end, TokenType.expressionEnd);
          break;
        }

        end = ++scanner.position;
      }

      text = scanner.substring(start, end);

      if (text.isNotEmpty) {
        yield Token(start, text, TokenType.text);
      }
    }
  }

  Iterable<Token> tokenize(String template, {String path}) => scan(StringScanner(template, sourceUrl: path));

  @override
  String toString() => 'Tokenizer()';
}

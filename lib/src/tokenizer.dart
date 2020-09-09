library tokenizer;

import 'package:meta/meta.dart';
import 'package:string_scanner/string_scanner.dart';

import 'environment.dart';
import 'util.dart';

part 'token.dart';

@immutable
class ExpressionTokenizer {
  ExpressionTokenizer(this.environment)
      : identifier = RegExp('[a-zA-Z][a-zA-Z0-9]*'),
        space = RegExp(r'\s+');

  final Environment environment;

  final Pattern identifier;

  final Pattern space;

  Iterable<Token> tokenize(String expression) {
    return scan(StringScanner(expression));
  }

  @protected
  Iterable<Token> scan(StringScanner scanner, {Pattern end}) sync* {
    end ??= environment.expressionEnd;

    while (!scanner.isDone) {
      if (scanner.scan(identifier)) {
        yield Token(scanner.lastMatch.start, TokenType.identifier, scanner.lastMatch[0]);
      } else if (scanner.scan(space)) {
        yield Token.simple(scanner.lastMatch.start, TokenType.space);
      } else if (scanner.matches(end)) {
        return;
      } else {
        break;
      }
    }
  }

  @override
  String toString() {
    return 'ExpressionTokenizer()';
  }
}

@immutable
class Tokenizer {
  @alwaysThrows
  static void error(StringScanner scanner, String message) {
    throw Exception('at ${scanner.position}: $message');
  }

  const Tokenizer(this.environment);

  final Environment environment;

  Iterable<Token> tokenize(String template, {String path}) {
    return scan(StringScanner(template, sourceUrl: path));
  }

  @protected
  Iterable<Token> scan(StringScanner scanner) sync* {
    final rules = <String>[environment.commentStart, environment.expressionStart, environment.statementStart];
    final reversed = rules.toList(growable: false);
    reversed.sort((a, b) => b.compareTo(a));

    while (!scanner.isDone) {
      var start = scanner.position;
      var end = start;

      String text;

      inner:
      while (!scanner.isDone) {
        int state;

        for (final rule in reversed) {
          if (scanner.scan(rule)) {
            state = rules.indexOf(rule);
            break;
          }
        }

        switch (state) {
          case 0:
            if (start < end) {
              text = scanner.substring(start, end);
              yield Token(start, TokenType.text, text);
            }

            yield Token.simple(scanner.lastMatch.start, TokenType.commentStart);

            start = scanner.lastMatch.end;
            end = start;

            while (!(scanner.isDone || scanner.matches(environment.commentEnd))) {
              scanner.position++;
            }

            end = scanner.position;
            text = scanner.substring(start, end).trim();

            if (text.isEmpty) {
              error(scanner, 'expected comment body.');
            }

            if (!scanner.scan(environment.commentEnd)) {
              error(scanner, 'expected comment end.');
            }

            yield Token(start, TokenType.comment, text);
            yield Token.simple(scanner.lastMatch.start, TokenType.commentEnd);

            start = scanner.lastMatch.end;
            end = start;

            break inner;

          case 1:
            text = scanner.substring(start, end);

            if (text.isNotEmpty) {
              yield Token(start, TokenType.text, text);
            }

            yield Token.simple(end, TokenType.expressionStart);
            yield* ExpressionTokenizer(environment).scan(scanner);

            if (!scanner.scan(environment.expressionEnd)) {
              error(scanner, 'expected expression end.');
            }

            end = scanner.lastMatch.start;
            start = end;

            yield Token.simple(end, TokenType.expressionEnd);

            break inner;

          case 2:
            text = scanner.substring(start, end);

            if (text.isNotEmpty) {
              yield Token(start, TokenType.text, text);
            }

            yield Token.simple(end, TokenType.statementStart);

            yield* ExpressionTokenizer(environment).scan(scanner);

            if (!scanner.scan(environment.statementEnd)) {
              error(scanner, 'expected statement end.');
            }

            start = scanner.lastMatch.end;
            end = start;

            yield Token.simple(scanner.lastMatch.start, TokenType.statementEnd);

            break inner;

          default:
            end = ++scanner.position;
        }
      }

      text = scanner.substring(start, end);

      if (text.isNotEmpty) {
        yield Token(start, TokenType.text, text);
      }
    }
  }

  @override
  String toString() {
    return 'Tokenizer()';
  }
}

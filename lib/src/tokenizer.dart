library tokenizer;

import 'package:meta/meta.dart';
import 'package:string_scanner/string_scanner.dart';

import 'environment.dart';

part 'token.dart';

@alwaysThrows
void _error(StringScanner scanner, String message) {
  throw Exception('at ${scanner.position}: $message');
}

@immutable
class ExpressionTokenizer {
  final Environment environment;

  final Pattern identifier;

  final Pattern space;

  ExpressionTokenizer(this.environment)
      : identifier = RegExp('[a-zA-Z][a-zA-Z0-9]*'),
        space = RegExp(r'\s+');

  @protected
  Iterable<Token> scan(StringScanner scanner, {String? end}) sync* {
    end ??= environment.expressionEnd;

    while (!scanner.isDone) {
      if (scanner.scan(identifier)) {
        yield Token(scanner.lastMatch.start, scanner.lastMatch[0], TokenType.word);
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

@immutable
class Tokenizer {
  final Environment environment;

  const Tokenizer(this.environment);

  @protected
  Iterable<Token> scan(StringScanner scanner) sync* {
    final expressionTokenizer = ExpressionTokenizer(environment);

    final rules = <String>[environment.commentStart, environment.expressionStart, environment.statementStart];
    final reversed = rules.toList(growable: false);
    reversed.sort((a, b) => b.compareTo(a));

    while (!scanner.isDone) {
      var start = scanner.position;
      var end = start;

      String text;

      inner:
      while (!scanner.isDone) {
        int? state;

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
              yield Token(start, text, TokenType.text);
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
              _error(scanner, 'expected comment body.');
            }

            if (!scanner.scan(environment.commentEnd)) {
              _error(scanner, 'expected comment end.');
            }

            yield Token(start, text, TokenType.comment);
            yield Token.simple(scanner.lastMatch.start, TokenType.commentEnd);
            start = scanner.lastMatch.end;
            end = start;

            break inner;

          case 1:
            text = scanner.substring(start, end);

            if (text.isNotEmpty) {
              yield Token(start, text, TokenType.text);
            }

            yield Token.simple(end, TokenType.expressionStart);
            yield* expressionTokenizer.scan(scanner);

            if (!scanner.scan(environment.expressionEnd)) {
              _error(scanner, 'expected expression end.');
            }

            end = scanner.lastMatch.start;
            start = end;

            yield Token.simple(end, TokenType.expressionEnd);
            break inner;

          case 2:
            text = scanner.substring(start, end);

            if (text.isNotEmpty) {
              yield Token(start, text, TokenType.text);
            }

            yield Token.simple(end, TokenType.statementStart);

            while (!(scanner.isDone || scanner.matches(environment.statementEnd))) {
              scanner.position++;
            }

            if (!scanner.scan(environment.statementEnd)) {
              _error(scanner, 'expected statement end.');
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
        yield Token(start, text, TokenType.text);
      }
    }
  }

  Iterable<Token> tokenize(String template, {String? path}) => scan(StringScanner(template, sourceUrl: path));

  @override
  String toString() => 'Tokenizer()';
}

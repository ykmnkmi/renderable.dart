library tokenizer;

import 'package:meta/meta.dart';
import 'package:string_scanner/string_scanner.dart';

import 'environment.dart';

part 'token.dart';

const Map<String, TokenType> operators = <String, TokenType>{
  '-': TokenType.sub,
  ',': TokenType.comma,
  ';': TokenType.semicolon,
  ':': TokenType.colon,
  '!=': TokenType.ne,
  '.': TokenType.dot,
  '(': TokenType.lParen,
  ')': TokenType.rParen,
  '[': TokenType.lBracket,
  ']': TokenType.rBracket,
  '{': TokenType.lBrace,
  '}': TokenType.rBracket,
  '*': TokenType.mul,
  '**': TokenType.pow,
  '/': TokenType.div,
  '//': TokenType.floorDiv,
  '%': TokenType.mod,
  '+': TokenType.add,
  '<': TokenType.lt,
  '<=': TokenType.lteq,
  '=': TokenType.assign,
  '==': TokenType.eq,
  '>': TokenType.gt,
  '>=': TokenType.gteq,
  '|': TokenType.pipe,
  '~': TokenType.tilde,
};

@alwaysThrows
void error(StringScanner scanner, String message) {
  scanner.error(message);
}

@immutable
@doNotStore
class ExpressionTokenizer {
  ExpressionTokenizer(this.environment)
      : spaceRe = RegExp(r'\s+'),
        nameRe = RegExp(r'[a-zA-Z][a-zA-Z0-9]*'),
        stringRe = RegExp(r"('([^'\\]*(?:\\.[^'\\]*)*)'" r'|"([^"\\]*(?:\\.[^"\\]*)*)")', dotAll: true),
        integerRe = RegExp(r'\d+'),
        floatRe = RegExp(r'\.\d+[eE][+\-]?\d+|\.\d+'),
        operatorsRe = RegExp(r'\+|-|\/\/|\/|\*\*|\*|%|~|\[|\]|\(|\)|{|}|==|!=|<=|>=|=|<|>|\.|:|\||,|;');

  final Environment environment;

  final Pattern spaceRe;

  final Pattern nameRe;

  final Pattern stringRe;

  final Pattern integerRe;

  final Pattern floatRe;

  final Pattern operatorsRe;

  Iterable<Token> tokenize(String expression) {
    return scan(StringScanner(expression));
  }

  @protected
  Iterable<Token> scan(StringScanner scanner, {Pattern end}) sync* {
    end ??= environment.variableEnd;

    while (!scanner.isDone) {
      if (scanner.scan(spaceRe)) {
        yield Token.simple(scanner.lastMatch.start, TokenType.whitespace);
      } else if (scanner.scan(nameRe)) {
        yield Token(scanner.lastMatch.start, TokenType.name, scanner.lastMatch[0]);
      } else if (scanner.scan(stringRe)) {
        yield Token(scanner.lastMatch.start, TokenType.string, scanner.lastMatch[2] ?? scanner.lastMatch[3]);
      } else if (scanner.scan(integerRe)) {
        final start = scanner.lastMatch.start;
        final integer = scanner.lastMatch[0];

        if (scanner.scan(floatRe)) {
          yield Token(start, TokenType.float, integer + scanner.lastMatch[0]);
        } else {
          yield Token(start, TokenType.integer, integer);
        }
      } else if (scanner.scan(operatorsRe)) {
        yield Token.simple(scanner.lastMatch.start, operators[scanner.lastMatch[0]]);
      } else if (scanner.matches(end)) {
        return;
      } else {
        error(scanner, 'unexpected char');
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
  const Tokenizer(this.environment);

  final Environment environment;

  Iterable<Token> tokenize(String template, {String path}) {
    return scan(StringScanner(template, sourceUrl: path));
  }

  @protected
  Iterable<Token> scan(StringScanner scanner) sync* {
    final rules = <String>[environment.commentStart, environment.variableStart, environment.blockStart];
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
          case 0: // comment
            if (start < end) {
              text = scanner.substring(start, end);
              yield Token(start, TokenType.text, text);
            }

            yield Token.simple(scanner.lastMatch.start, TokenType.commentBegin);

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

          case 1: // expression
            text = scanner.substring(start, end);

            if (text.isNotEmpty) {
              yield Token(start, TokenType.text, text);
            }

            yield Token.simple(end, TokenType.variableBegin);
            yield* ExpressionTokenizer(environment).scan(scanner);

            if (!scanner.scan(environment.variableEnd)) {
              error(scanner, 'expected expression end');
            }

            end = scanner.lastMatch.start;
            start = end;

            yield Token.simple(end, TokenType.variableEnd);

            break inner;

          case 2: // statement
            text = scanner.substring(start, end);

            if (text.isNotEmpty) {
              yield Token(start, TokenType.text, text);
            }

            yield Token.simple(end, TokenType.blockBegin);

            yield* ExpressionTokenizer(environment).scan(scanner);

            if (!scanner.scan(environment.blockEnd)) {
              error(scanner, 'expected statement end');
            }

            start = scanner.lastMatch.end;
            end = start;

            yield Token.simple(scanner.lastMatch.start, TokenType.blockEnd);

            break inner;

          default:
            scanner.position += 1;
            end = scanner.position;
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

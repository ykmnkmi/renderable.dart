library tokenizer;

import 'package:meta/meta.dart';
import 'package:string_scanner/string_scanner.dart';

import 'environment.dart';
import 'utils.dart';

part 'token.dart';

const Map<String, String> operators = <String, String>{
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
  '}': TokenType.rBrace,
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

@immutable
@doNotStore
class ExpressionTokenizer {
  ExpressionTokenizer(this.environment)
      : whiteSpaceRe = RegExp(r'\s+'),
        nameRe = RegExp(r'[a-zA-Z][a-zA-Z0-9]*'),
        stringRe = RegExp(r"('([^'\\]*(?:\\.[^'\\]*)*)'" r'|"([^"\\]*(?:\\.[^"\\]*)*)")', dotAll: true),
        integerRe = RegExp(r'\d+'),
        floatRe = RegExp(r'\.\d+[eE][+\-]?\d+|\.\d+'),
        operatorsRe = RegExp(r'\+|-|\/\/|\/|\*\*|\*|%|~|\[|\]|\(|\)|{|}|==|!=|<=|>=|=|<|>|\.|:|\||,|;');

  final Environment environment;

  final Pattern whiteSpaceRe;

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
      if (scanner.scan(whiteSpaceRe)) {
        // yield Token.simple(scanner.lastMatch.start, TokenType.whiteSpace);
      } else if (scanner.matches(end)) {
        return;
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
      } else {
        throw 'unexpected char: ${scanner.rest[0]}';
      }
    }

    yield Token.simple(scanner.position, TokenType.eof);
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
    final rules = <String>[environment.commentBegin, environment.variableBegin, environment.blockBegin];
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

            yield Token(scanner.lastMatch.start, TokenType.commentBegin, environment.commentBegin);

            start = scanner.lastMatch.end;
            end = start;

            while (!(scanner.isDone || scanner.matches(environment.commentEnd))) {
              scanner.position++;
            }

            end = scanner.position;
            text = scanner.substring(start, end).trim();

            if (text.isEmpty) {
              throw 'expected comment body.';
            }

            if (!scanner.scan(environment.commentEnd)) {
              throw 'expected comment end.';
            }

            yield Token(start, TokenType.comment, text);
            yield Token(scanner.lastMatch.start, TokenType.commentEnd, environment.commentEnd);

            start = scanner.lastMatch.end;
            end = start;

            break inner;

          case 1: // expression
            text = scanner.substring(start, end);

            if (text.isNotEmpty) {
              yield Token(start, TokenType.text, text);
            }

            yield Token(end, TokenType.variableBegin, environment.variableBegin);
            yield* ExpressionTokenizer(environment).scan(scanner);

            if (!scanner.scan(environment.variableEnd)) {
              throw 'expected expression end';
            }

            end = scanner.lastMatch.start;
            start = end;
            yield Token(end, TokenType.variableEnd, environment.variableEnd);
            break inner;
          case 2: // statement
            text = scanner.substring(start, end);

            if (text.isNotEmpty) {
              yield Token(start, TokenType.text, text);
            }

            yield Token(end, TokenType.blockBegin, environment.blockBegin);

            yield* ExpressionTokenizer(environment).scan(scanner);

            if (!scanner.scan(environment.blockEnd)) {
              throw 'expected statement end';
            }

            start = scanner.lastMatch.end;
            end = start;

            yield Token(scanner.lastMatch.start, TokenType.blockEnd, environment.blockEnd);

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

    yield Token.simple(scanner.position, TokenType.eof);
  }

  @override
  String toString() {
    return 'Tokenizer()';
  }
}

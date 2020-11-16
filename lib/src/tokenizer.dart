library tokenizer;

import 'package:meta/meta.dart';
import 'package:string_scanner/string_scanner.dart';

import 'environment.dart';

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

const List<String> defaultIgnoredTokens = <String>[
  TokenType.whitespace,
  TokenType.commentBegin,
  TokenType.comment,
  TokenType.commentEnd,
  TokenType.rawBegin,
  TokenType.rawEnd,
  TokenType.lineCommentBegin,
  TokenType.lineCommentEnd,
  TokenType.lineComment,
];

class Tokenizer {
  Tokenizer(this.environment, {this.ignoredTokens = defaultIgnoredTokens})
      : newLineRe = RegExp(r'(\r\n|\r|\n)'),
        whiteSpaceRe = RegExp(r'\s+'),
        nameRe = RegExp(r'[a-zA-Z][a-zA-Z0-9]*'),
        stringRe = RegExp(r"('([^'\\]*(?:\\.[^'\\]*)*)'" r'|"([^"\\]*(?:\\.[^"\\]*)*)")', dotAll: true),
        integerRe = RegExp(r'(\d+_)*\d+'),
        floatRe = RegExp(r'\.(\d+_)*\d+[eE][+\-]?(\d+_)*\d+|\.(\d+_)*\d+'),
        operatorsRe = RegExp(r'\+|-|\/\/|\/|\*\*|\*|%|~|\[|\]|\(|\)|{|}|==|!=|<=|>=|=|<|>|\.|:|\||,|;');

  final Environment environment;

  final List<String> ignoredTokens;

  final Pattern newLineRe;

  final Pattern whiteSpaceRe;

  final Pattern nameRe;

  final Pattern stringRe;

  final Pattern integerRe;

  final Pattern floatRe;

  final Pattern operatorsRe;

  String normalizeNewLines(String value) {
    return value.replaceAll(newLineRe, environment.newLine);
  }

  Iterable<Token> tokenize(String template, {String path}) sync* {
    for (final token in scan(StringScanner(template, sourceUrl: path))) {
      if (ignoredTokens.any(token.test)) {
        continue;
      } else if (token.test(TokenType.lineStatementBegin)) {
        yield token.change(type: TokenType.lineStatementBegin);
      } else if (token.test(TokenType.lineStatementEnd)) {
        yield token.change(type: TokenType.lineStatementEnd);
      } else if (token.test(TokenType.data) || token.test(TokenType.string)) {
        yield token.change(value: normalizeNewLines(token.value));
      } else if (token.test(TokenType.integer) || token.test(TokenType.float)) {
        yield token.change(value: token.value.replaceAll('_', ''));
      } else {
        yield token;
      }
    }
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
              yield Token(start, TokenType.data, text);
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
              throw 'expected comment body';
            }

            if (!scanner.scan(environment.commentEnd)) {
              throw 'expected comment end';
            }

            yield Token(start, TokenType.comment, text);
            yield Token(scanner.lastMatch.start, TokenType.commentEnd, environment.commentEnd);
            start = scanner.lastMatch.end;
            end = start;
            break inner;
          case 1: // expression
            text = scanner.substring(start, end);

            if (text.isNotEmpty) {
              yield Token(start, TokenType.data, text);
            }

            yield Token(end, TokenType.variableBegin, environment.variableBegin);
            yield* expression(scanner);

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
              yield Token(start, TokenType.data, text);
            }

            yield Token(end, TokenType.blockBegin, environment.blockBegin);
            yield* expression(scanner);

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
        yield Token(start, TokenType.data, text);
      }
    }

    yield Token.simple(scanner.position, TokenType.eof);
  }

  Iterable<Token> expression(StringScanner scanner) sync* {
    while (!scanner.isDone) {
      if (scanner.scan(whiteSpaceRe)) {
        yield Token(scanner.lastMatch.start, TokenType.whitespace, scanner.lastMatch[0]);
      } else if (scanner.matches(environment.variableEnd)) {
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
    return 'Tokenizer()';
  }
}

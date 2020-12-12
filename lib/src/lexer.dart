library tokenizer;

import 'package:meta/meta.dart';
import 'package:string_scanner/string_scanner.dart';

import 'configuration.dart';

part 'token.dart';

const Map<String, String> operators = <String, String>{
  '-': 'sub',
  ',': 'comma',
  ';': 'semicolon',
  ':': 'colon',
  '!=': 'ne',
  '.': 'dot',
  '(': 'lparen',
  ')': 'rparen',
  '[': 'lbracket',
  ']': 'rbracket',
  '{': 'lbrace',
  '}': 'rbrace',
  '*': 'mul',
  '**': 'pow',
  '/': 'div',
  '//': 'floordiv',
  '%': 'mod',
  '+': 'add',
  '<': 'lt',
  '<=': 'lteq',
  '=': 'assign',
  '==': 'eq',
  '>': 'gt',
  '>=': 'gteq',
  '|': 'pipe',
  '~': 'tilde',
};

const List<String> defaultIgnoredTokens = <String>[
  'whitespace',
  'comment_begin',
  'comment',
  'comment_end',
  'raw_begin',
  'raw_end',
  'linecomment_begin',
  'linecomment_end',
  'linecomment',
];

class Lexer {
  Lexer(this.configuration, {this.ignoredTokens = defaultIgnoredTokens})
      : newLineRe = RegExp(r'(\r\n|\r|\n)'),
        whiteSpaceRe = RegExp(r'\s+'),
        nameRe = RegExp(r'[a-zA-Z][a-zA-Z0-9]*'),
        stringRe = RegExp(r"('([^'\\]*(?:\\.[^'\\]*)*)'" r'|"([^"\\]*(?:\\.[^"\\]*)*)")', dotAll: true),
        integerRe = RegExp(r'(\d+_)*\d+'),
        floatRe = RegExp(r'\.(\d+_)*\d+[eE][+\-]?(\d+_)*\d+|\.(\d+_)*\d+'),
        operatorsRe = RegExp(r'\+|-|\/\/|\/|\*\*|\*|%|~|\[|\]|\(|\)|{|}|==|!=|<=|>=|=|<|>|\.|:|\||,|;'),
        commentBegin = compile(configuration.commentBegin),
        commentEnd = compile(configuration.commentEnd),
        variableBegin = compile(configuration.variableBegin),
        variableEnd = compile(configuration.variableEnd),
        blockBegin = compile(configuration.blockBegin),
        blockEnd = compile(configuration.blockEnd);

  final Configuration configuration;

  final List<String> ignoredTokens;

  final Pattern newLineRe;

  final Pattern whiteSpaceRe;

  final Pattern nameRe;

  final Pattern stringRe;

  final Pattern integerRe;

  final Pattern floatRe;

  final Pattern operatorsRe;

  final Pattern commentBegin;

  final Pattern commentEnd;

  final Pattern variableBegin;

  final Pattern variableEnd;

  final Pattern blockBegin;

  final Pattern blockEnd;

  String normalizeNewLines(String value) {
    return value.replaceAll(newLineRe, configuration.newLine);
  }

  Iterable<Token> tokenize(String template, {String? path}) sync* {
    for (final token in scan(StringScanner(template, sourceUrl: path))) {
      if (ignoredTokens.any(token.test)) {
        continue;
      } else if (token.test('linestatement_begin')) {
        yield token.change(type: 'linestatement_begin');
      } else if (token.test('linestatement_end')) {
        yield token.change(type: 'linestatement_end');
      } else if (token.test('data') || token.test('string')) {
        yield token.change(value: normalizeNewLines(token.value));
      } else if (token.test('integer') || token.test('float')) {
        yield token.change(value: token.value.replaceAll('_', ''));
      } else {
        yield token;
      }
    }
  }

  @protected
  Iterable<Token> scan(StringScanner scanner) sync* {
    late int start, end;
    late String text;

    final rules = <Rule>[
      Rule(
        configuration.commentBegin,
        commentBegin,
        (scanner) sync* {
          if (start < end) {
            text = scanner.substring(start, end);
            yield Token(start, 'data', text);
          }

          yield Token(scanner.lastMatch!.start, 'comment_begin', configuration.commentBegin);
          start = scanner.lastMatch!.end;
          end = start;

          while (!(scanner.isDone || scanner.matches(commentEnd))) {
            scanner.position++;
          }

          end = scanner.position;
          text = scanner.substring(start, end).trim();

          if (text.isEmpty) {
            throw 'expected comment body';
          }

          if (!scanner.scan(commentEnd)) {
            throw 'expected comment end';
          }

          yield Token(start, 'comment', text);
          yield Token(scanner.lastMatch!.start, 'comment_end', configuration.commentEnd);
          start = scanner.lastMatch!.end;
          end = start;
        },
      ),
      Rule(
        configuration.variableBegin,
        variableBegin,
        (scanner) sync* {
          text = scanner.substring(start, end);

          if (text.isNotEmpty) {
            yield Token(start, 'data', text);
          }

          yield Token(end, 'variable_begin', configuration.variableBegin);
          yield* expression(scanner);

          if (!scanner.scan(variableEnd)) {
            throw 'expected expression end';
          }

          end = scanner.lastMatch!.start;
          start = end;
          yield Token(end, 'variable_end', configuration.variableEnd);
        },
      ),
      Rule(
        configuration.blockBegin,
        blockBegin,
        (scanner) sync* {
          text = scanner.substring(start, end);

          if (text.isNotEmpty) {
            yield Token(start, 'data', text);
          }

          yield Token(end, 'block_begin', configuration.blockBegin);
          yield* expression(scanner);

          if (!scanner.scan(blockEnd)) {
            throw 'expected statement end';
          }

          start = scanner.lastMatch!.end;
          end = start;
          yield Token(scanner.lastMatch!.start, 'block_end', configuration.blockEnd);
        },
      ),
    ];

    rules.sort((a, b) => b.raw.compareTo(a.raw));

    while (!scanner.isDone) {
      start = scanner.position;
      end = start;
      text = '';

      inner:
      while (!scanner.isDone) {
        for (final rule in rules) {
          if (scanner.scan(rule.pattern)) {
            yield* rule.parse(scanner);
            break inner;
          }
        }

        scanner.position += 1;
        end = scanner.position;
      }

      text = scanner.substring(start, end);

      if (text.isNotEmpty) {
        yield Token(start, 'data', text);
      }
    }

    yield Token.simple(scanner.position, 'eof');
  }

  Iterable<Token> expression(StringScanner scanner) sync* {
    while (!scanner.isDone) {
      // print(scanner.rest);
      if (scanner.scan(whiteSpaceRe)) {
        yield Token(scanner.lastMatch!.start, 'whitespace', scanner.lastMatch![0]!);
      } else if (scanner.scan(nameRe)) {
        yield Token(scanner.lastMatch!.start, 'name', scanner.lastMatch![0]!);
      } else if (scanner.scan(stringRe)) {
        yield Token(scanner.lastMatch!.start, 'string', scanner.lastMatch![2] ?? scanner.lastMatch![3] ?? '');
      } else if (scanner.scan(integerRe)) {
        final start = scanner.lastMatch!.start;
        final integer = scanner.lastMatch![0]!;

        if (scanner.scan(floatRe)) {
          yield Token(start, 'float', integer + scanner.lastMatch![0]!);
        } else {
          yield Token(start, 'integer', integer);
        }
      } else if (scanner.scan(operatorsRe)) {
        yield Token.simple(scanner.lastMatch!.start, operators[scanner.lastMatch![0]]!);
      } else {
        break;
      }
    }
  }

  @override
  String toString() {
    return 'Tokenizer()';
  }
}

class Rule {
  Rule(this.raw, this.pattern, this.parse);

  final String raw;

  final Pattern pattern;

  final Iterable<Token> Function(StringScanner scanner) parse;
}

RegExp compile(String pattern) {
  return RegExp(RegExp.escape(pattern));
}

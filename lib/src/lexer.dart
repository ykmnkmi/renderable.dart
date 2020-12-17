library tokenizer;

import 'dart:io' show exit;

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

RegExp compile(String pattern, [bool escape = true]) {
  return RegExp(escape ? RegExp.escape(pattern) : pattern);
}

class Rule {
  Rule(this.name, this.pattern, this.regExp, [this.parse]);

  final String name;

  final String pattern;

  final RegExp regExp;

  final Iterable<Token> Function(StringScanner scanner)? parse;
}

class Lexer {
  Lexer(Configuration configuration, {this.ignoredTokens = defaultIgnoredTokens})
      : newLine = configuration.newLine,
        newLineRe = RegExp(r'(\r\n|\r|\n)'),
        whiteSpaceRe = RegExp(r'\s+'),
        nameRe = RegExp(r'[a-zA-Z][a-zA-Z0-9]*'),
        stringRe = RegExp(r"('([^'\\]*(?:\\.[^'\\]*)*)'" r'|"([^"\\]*(?:\\.[^"\\]*)*)")', dotAll: true),
        integerRe = RegExp(r'(\d+_)*\d+'),
        floatRe = RegExp(r'\.(\d+_)*\d+[eE][+\-]?(\d+_)*\d+|\.(\d+_)*\d+'),
        operatorsRe = RegExp(r'\+|-|\/\/|\/|\*\*|\*|%|~|\[|\]|\(|\)|{|}|==|!=|<=|>=|=|<|>|\.|:|\||,|;') {
    commentBegin = compile(configuration.commentBegin);
    commentEnd = compile(configuration.commentEnd);
    variableBegin = compile(configuration.variableBegin);
    variableEnd = compile(configuration.variableEnd);
    blockBegin = compile(configuration.blockBegin);
    blockEnd = compile(configuration.blockEnd);

    final tagRules = <Rule>[
      Rule(
        'comment_begin',
        configuration.commentBegin,
        commentBegin,
        (scanner) sync* {
          yield Token(scanner.lastMatch!.start, 'comment_begin', configuration.commentBegin);
          // yield Token(scanner.position, 'comment', text);
          yield Token(scanner.lastMatch!.start, 'comment_end', configuration.commentEnd);
        },
      ),
      Rule(
        'variable_begin',
        configuration.variableBegin,
        variableBegin,
        (scanner) sync* {
          yield Token(scanner.lastMatch!.start, 'variable_begin', configuration.variableBegin);
          yield* expression(scanner, variableEnd);

          if (!scanner.scan(variableEnd)) {
            throw 'expected expression end';
          }

          yield Token(scanner.lastMatch!.start, 'variable_end', configuration.variableEnd);
        },
      ),
      Rule(
        'block_begin',
        configuration.blockBegin,
        blockBegin,
        (scanner) sync* {
          yield Token(scanner.lastMatch!.start, 'block_begin', configuration.blockBegin);
          yield* expression(scanner, blockEnd);

          if (!scanner.scan(blockEnd)) {
            throw 'expected statement end';
          }

          yield Token(scanner.lastMatch!.start, 'block_end', configuration.blockEnd);
        },
      ),
    ];

    tagRules.sort((a, b) => b.pattern.compareTo(a.pattern));

    final rootPartsRe = tagRules.map((rule) => '(?<${rule.name}>${rule.regExp.pattern})').join('|');
    final dataRe = '(.*?)(?:${rootPartsRe})';

    rules = <String, List<Rule>>{
      'root': <Rule>[
        Rule(
          'data',
          dataRe,
          compile(dataRe, false),
          (scanner) sync* {
            final match = scanner.lastMatch as RegExpMatch;
            final data = match[1]!;

            if (data.isNotEmpty) {
              yield Token(match.start, 'data', data);
              scanner.position = match.start + data.length;
            } else {
              scanner.position = match.start;
            }

            final state = match.groupNames.firstWhere((groupName) => match.namedGroup(groupName) != null);
            yield* scan(scanner, state);
          },
        ),
        Rule(
          'data',
          '.+',
          compile('.+', false),
          (scanner) sync* {
            yield Token(scanner.position, 'data', scanner.lastMatch![0]!);
          },
        ),
      ],
      for (final rule in tagRules) rule.name: <Rule>[rule]
    };
  }

  final List<String> ignoredTokens;

  final String newLine;

  final RegExp newLineRe;

  final RegExp whiteSpaceRe;

  final RegExp nameRe;

  final RegExp stringRe;

  final RegExp integerRe;

  final RegExp floatRe;

  final RegExp operatorsRe;

  late RegExp commentBegin;

  late RegExp commentEnd;

  late RegExp variableBegin;

  late RegExp variableEnd;

  late RegExp blockBegin;

  late RegExp blockEnd;

  late Map<String, List<Rule>> rules;

  String normalizeNewLines(String value) {
    return value.replaceAll(newLineRe, newLine);
  }

  Iterable<Token> tokenize(String template, {String? path}) sync* {
    final scanner = StringScanner(template, sourceUrl: path);
    var notFound = true; // is needed?

    while (!scanner.isDone) {
      for (final token in scan(scanner)) {
        notFound = false;

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

      if (notFound) {
        throw 'unexpected char ${scanner.rest[0]} at ${scanner.position}';
      }
    }

    yield Token.simple(template.length, 'eof');
  }

  @protected
  Iterable<Token> scan(StringScanner scanner, [String state = 'root']) sync* {
    for (final rule in rules[state]!) {
      if (scanner.scan(rule.regExp)) {
        yield* rule.parse!(scanner);
        break;
      }
    }
  }

  Iterable<Token> expression(StringScanner scanner, RegExp end) sync* {
    final stack = <String>[];

    while (!scanner.isDone) {
      if (stack.isEmpty && scanner.matches(end)) {
        return;
      } else if (scanner.scan(whiteSpaceRe)) {
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
        final operator = scanner.lastMatch![0]!;

        if (operator == '(') {
          stack.add(')');
        } else if (operator == '[') {
          stack.add(']');
        } else if (operator == '{') {
          stack.add('}');
        } else if (operator == ')' || operator == ']' || operator == '}') {
          if (stack.isEmpty) {
            scanner.position -= 1;
            return;
          }

          final expected = stack.removeLast();

          if (operator != expected) {
            throw 'unexpected char ${scanner.rest[0]} at ${scanner.position}\'$operator\', expected \'$expected\'';
          }
        }

        yield Token.simple(scanner.lastMatch!.start, operators[operator]!);
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

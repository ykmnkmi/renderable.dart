import 'dart:convert' show LineSplitter;
import 'dart:io' show exit;

import 'enirvonment.dart';
import 'lexer.dart';

class OptionalLStrip {
  OptionalLStrip(this.type, this.tag);

  String type;

  String tag;
}

List<List<dynamic>> compileRules(Environment environment) {
  final result = <List<dynamic>>[
    // [
    //   environment.commentBegin.length,
    //   'comment_begin',
    //   RegExp.escape(environment.commentBegin),
    //   null,
    // ],
    [
      environment.variableBegin.length,
      'variable_begin',
      RegExp.escape(environment.variableBegin),
      null,
    ],
    // [
    //   environment.blockBegin.length,
    //   'block_begin',
    //   RegExp.escape(environment.blockBegin),
    //   null,
    // ],
    // [
    //   environment.lineCommentPrefix.length,
    //   'linecomment_begin',
    //   r'(?:^|(?<=\S))[^\S\r\n]*' + RegExp.escape(environment.lineCommentPrefix),
    //   null,
    // ],
    // [
    //   environment.lineStatementPrefix.length,
    //   'linestatement_begin',
    //   r'^[ \t\v]*' + RegExp.escape(environment.lineStatementPrefix),
    //   null,
    // ],
  ];

  result.sort((a, b) {
    return (a[0] as int).compareTo(b[0] as int);
  });

  return result.map<List<dynamic>>((list) => list.sublist(1)).toList();
}

class Rexer {
  Rexer(this.environment)
      : whiteSpaceRe = RegExp(r'\s+'),
        nameRe = RegExp(r'[a-zA-Z][a-zA-Z0-9]*'),
        stringRe = RegExp(r"('([^'\\]*(?:\\.[^'\\]*)*)'" r'|"([^"\\]*(?:\\.[^"\\]*)*)")', dotAll: true),
        integerRe = RegExp(r'(\d+_)*\d+'),
        floatRe = RegExp(r'\.(\d+_)*\d+[eE][+\-]?(\d+_)*\d+|\.(\d+_)*\d+'),
        operatorsRe = RegExp(r'\+|-|\/\/|\/|\*\*|\*|%|~|\[|\]|\(|\)|{|}|==|!=|<=|>=|=|<|>|\.|:|\||,|;'),
        lStripUnlessReg = environment.lStripBlocks ? compile(r'[^ \t]') : null,
        newLine = environment.newLine,
        keepTrailingNewLine = environment.keepTrailingNewLine {
    final tagRules = <List<dynamic>>[
      [
        whiteSpaceRe,
        ['whitespace'],
        null,
      ],
      [
        floatRe,
        ['float'],
        null,
      ],
      [
        integerRe,
        ['integer'],
        null,
      ],
      [
        nameRe,
        ['name'],
        null,
      ],
      [
        stringRe,
        ['string'],
        null,
      ],
      [
        operatorsRe,
        ['operator'],
        null,
      ],
    ];

    final rootTagRules = compileRules(environment);

    final commentEndRe = RegExp.escape(environment.commentEnd);
    final variableEndRe = RegExp.escape(environment.variableEnd);
    final blockStartRe = RegExp.escape(environment.blockBegin);
    final blockEndRe = RegExp.escape(environment.blockEnd);

    final blockSuffixRe = environment.trimBlocks ? '\\n?' : '';

    final rootPartsRe = [
      '(?<raw_begin>${blockStartRe}(\\-|\\+|)\\s*raw\\s*(?:\\-${blockEndRe}\\s*|${blockEndRe}))',
      for (final rule in rootTagRules) '(?<${rule[0]}>${rule[1]}(\\-|\\+|))'
    ].join('|');

    RegExp compile(String pattern) {
      print(pattern);
      return RegExp(pattern, dotAll: true, multiLine: true);
    }

    // global lexing rules
    rules = <String, List<List<dynamic>>>{
      'root': [
        [
          // directives
          compile('(.*?)(?:${rootPartsRe})'),
          [OptionalLStrip('data', '#bygroup')],
          '#bygroup',
        ],
        [
          // data
          compile('.+'),
          ['data'],
          null,
        ],
      ],

      // comments
      // 'comment_begin': [
      //   [
      //     compile('(.*?)((?:\\+${commentEndRe}|\\-${commentEndRe}\\s*|${commentEndRe}${blockSuffixRe}))'),
      //     ['comment', 'comment_end'],
      //     '#pop',
      //   ],
      //   [
      //     compile(r'(.)'),
      //     [Exception('Missing end of comment tag')],
      //     null,
      //   ],
      // ],

      // variables
      'variable_begin': [
        [
          compile('\\-${variableEndRe}\\s*|${variableEndRe}'),
          ['variable_end'],
          '#pop',
        ],
        ...tagRules,
      ],

      // // blocks
      // 'block_begin': [
      //   [
      //     compile('(?:\\+${blockEndRe}|\\-${blockEndRe}\\s*|${blockEndRe}${blockSuffixRe})'),
      //     ['block_end'],
      //     '#pop',
      //   ],
      //   ...tagRules,
      // ],

      // // raw block
      // 'raw_begin': [
      //   [
      //     compile('(.*?)((?:${blockStartRe}(\\-|\\+|))\\s*endraw\\s*(?:\\+${blockEndRe}|\\-${blockEndRe}\\s*|${blockEndRe}${blockSuffixRe}))'),
      //     [OptionalLStrip('data', 'raw_end')],
      //     '#pop',
      //   ],
      //   [
      //     compile('(.)'),
      //     [
      //       Exception('Missing end of raw directive'),
      //     ],
      //     null
      //   ],
      // ],

      // // line statements
      // 'linestatement_begin': [
      //   [
      //     compile('\\s*(\\n|\$)'),
      //     ['linestatement_end'],
      //     '#pop',
      //   ],
      //   ...tagRules,
      // ],

      // // line comments
      // 'linecomment_begin': [
      //   [
      //     compile('(.*?)()(?=\\n|\$)'),
      //     ['linecomment', 'linecomment_end'],
      //     '#pop',
      //   ],
      // ],
    };
  }

  final Environment environment;
  final Pattern whiteSpaceRe;
  final Pattern nameRe;
  final Pattern stringRe;
  final Pattern integerRe;
  final Pattern floatRe;
  final Pattern operatorsRe;
  final RegExp? lStripUnlessReg;
  final String newLine;
  final bool keepTrailingNewLine;

  late Map<String, List<List<dynamic>>> rules;

  Iterable<Token> tokenize(String source) sync* {
    final lines = const LineSplitter().convert(source);

    if (keepTrailingNewLine && source.isNotEmpty) {
      if (source.endsWith('\r\n') || source.endsWith('\r') || source.endsWith('\n')) {
        lines.add('');
      }
    }

    source = lines.join('\n');

    final stack = <String>['root'];
    var position = 0;
    var line = 0;

    final stateTokens = rules[stack.last]!;
    final sourceLength = source.length;
    final balancingStack = <String>[];
    var newLinesStripped = 0;
    var lineStarting = true;

    while (true) {
      for (final state in stateTokens) {
        final regex = state[0] as RegExp;
        final tokens = state[1] as List;
        final newState = state[2] as String?;
        print(regex);

        final match = regex.firstMatch(source.substring(position));

        if (match == null) {
          continue;
        }

        if (balancingStack.isNotEmpty && tokens.any(const <String>['variable_end', 'block_end', 'linestatement_end'].contains)) {
          continue;
        }

        for (var i = 0; i <= match.groupCount; i += 1) {
          final token = tokens[i];
          print(token);
          print(match[i]);
        }

        exit(0);
      }
    }
  }
}

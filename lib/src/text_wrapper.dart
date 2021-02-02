import 'package:meta/meta.dart';

class TextWrapper {
  static const String whitespaces = '\t\n\x0b\x0c\r ';

  static const Map<int, int> unicodeWhiteSpaceTranslateTable = <int, int>{9: 32, 10: 32, 11: 32, 12: 32, 13: 32};

  TextWrapper(this.width,
      {this.initialIndent = '',
      this.subsequentIndent = '',
      this.expandTabs = true,
      this.replaceWhitespace = true,
      this.fixSentenceEndings = false,
      this.breakOnHyphens = true,
      this.tabSize = 8,
      this.maxLines,
      this.placeholder = ' [...]'}) {
    final whitespace = '[${RegExp.escape(whitespaces)}]';
    final noWhitespace = '[^${whitespace.substring(1)}';
    final wordPuctuation = '[\\w!"\'&.,?]';
    final letter = '[^\\d\\W]';
    wordSeparatorRe = RegExp('(${whitespace}s+|(?<=${wordPuctuation}s)-{2,}(?=\\w)|${noWhitespace}s+?(?:-(?:(?<=$letter{2}-)|'
        '(?<=$letter-$letter-))(?=$letter-?$letter)|(?=${whitespace}s|\\Z)|(?<=${wordPuctuation}s)(?=-{2,}\\w)))');
    wordSeparatorSimpleRe = RegExp('($whitespace)+');
    sentenceEndRe = RegExp('[a-z][\\.\\!\\?][\\"\\\']?\\Z');
  }

  final int width;

  final String initialIndent;

  final String subsequentIndent;

  final bool expandTabs;

  final bool replaceWhitespace;

  final bool fixSentenceEndings;

  final bool breakOnHyphens;

  final int tabSize;

  final int? maxLines;

  final String placeholder;

  late RegExp wordSeparatorRe;

  late RegExp wordSeparatorSimpleRe;

  late RegExp sentenceEndRe;

  /// Munge whitespace in text: expand tabs and convert all other whitespace characters to spaces.
  ///
  /// Eg.
  ///
  ///     " foo\\tbar\\n\\nbaz"
  ///
  /// becomes
  ///
  ///     " foo    bar  baz"
  @protected
  String mungeWhiteSpace(String text) {
    if (expandTabs) {
      text = text.expandTabs(tabSize);
    }

    if (replaceWhitespace) {
      text = text.translate(unicodeWhiteSpaceTranslateTable);
    }

    return text;
  }

  /// Split the text to wrap into indivisible chunks.
  ///
  /// Chunks are not quite the same as words; see [wrapChunks] for full details.
  ///
  /// As an example, the text
  ///
  ///     'Look, goof-ball -- use the -b option!'
  ///
  /// breaks into the following chunks:
  ///
  ///     ['Look,', ' ', 'goof-', 'ball', ' ', '--', ' ', 'use', ' ', 'the', ' ', '-b', ' ', 'option!']
  ///
  /// if [breakOnHyphens] is true:
  ///
  ///     ['Look,', ' ', 'goof-ball', ' ', '--', ' ', 'use', ' ', 'the', ' ', '-b', ' ', option!']
  ///
  /// otherwise.
  @protected
  List<String> split(String text) {
    late List<String> chunks;

    if (breakOnHyphens) {
      chunks = text.split(wordSeparatorRe);
    } else {
      chunks = text.split(wordSeparatorSimpleRe);
    }

    return <String>[
      for (final chunk in chunks)
        if (chunks.isNotEmpty) chunk
    ];
  }

  @protected
  List<String> splitChunks(String text) {
    text = mungeWhiteSpace(text);
    return split(text);
  }

  /// Wrap a sequence of text chunks and return a list of lines of length 'self.width' or less.
  ///
  /// (If 'break_long_words' is false, some lines may be longer than this.)
  ///
  /// Chunks correspond roughly to words and the whitespace between them: each chunk is indivisible
  /// (modulo 'break_long_words'), but a line break can come between any two chunks.
  ///
  /// Chunks should not have internal whitespace; ie. a chunk is either all whitespace or a "word".
  /// Whitespace chunks will be removed from the beginning and end of lines, but apart from that whitespace is preserved.
  @protected
  String wrapChunks(List<String> chunks) {
    if (width < 0) {
      throw ArgumentError.value(width, 'width');
    }

    final lines = <String>[];
    late String indent;

    if (maxLines != null) {
      if (maxLines! > 1) {
        indent = subsequentIndent;
      } else {
        indent = initialIndent;
      }

      if (indent.length + placeholder.length > width) {}
    }

    throw UnimplementedError();
  }

  String wrap(String text) {
    final chunks = splitChunks(text);

    if (fixSentenceEndings) {
      for (var i = 0; i < chunks.length - 1;) {
        if (chunks[i + 1] == ' ' && chunks[i].contains(sentenceEndRe)) {
          chunks[i + 1] = '  ';
          i += 2;
        } else {
          i += 1;
        }
      }
    }

    return wrapChunks(chunks);
  }
}

extension on String {
  String expandTabs(int tabSize) {
    final spaces = ' ' * tabSize;
    return replaceAll('\t', spaces);
  }

  String translate(Map<int, int> table) {
    return String.fromCharCodes(<int>[for (final codeUnit in codeUnits) table.containsKey(codeUnit) ? table[codeUnit]! : codeUnit]);
  }
}

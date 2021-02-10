import 'package:meta/meta.dart';

class TextWrapper {
  static final String whitespaces = '\t\n\x0b\x0c\r ';

  static final Map<int, int> unicodeWhiteSpaceTranslateTable = const <int, int>{9: 32, 10: 32, 11: 32, 12: 32, 13: 32};

  TextWrapper({
    this.width = 80,
    this.initialIndent = '',
    this.subsequentIndent = '',
    this.expandTabs = true,
    this.replaceWhitespace = true,
    this.fixSentenceEndings = false,
    this.dropWhitespace = true,
    this.breakOnHyphens = true,
    this.tabSize = 8,
    this.maxLines = -1,
    this.placeholder = ' [...]',
  }) {
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

  final bool dropWhitespace;

  final bool breakOnHyphens;

  final int tabSize;

  final int maxLines;

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

  /// Handle a chunk of text (most likely a word, not whitespace) that is too long to fit in any line.
  @protected
  void handleLongWord(List<String> chunks, List<String> currentLine, int currentLength, int width) {}

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
  List<String> wrapChunks(List<String> chunks) {
    if (width < 0) {
      throw Exception('invalid width $width (must be > 0)');
    }

    final lines = <String>[];

    if (maxLines != -1) {
      final indent = maxLines > 1 ? subsequentIndent : initialIndent;

      if (indent.length + placeholder.trimLeft().length > width) {
        throw Exception('placeholder too large for max width');
      }
    }

    chunks = List<String>.generate(chunks.length, (index) => chunks[chunks.length - index - 1]);

    while (chunks.isNotEmpty) {
      print('hehe');

      var currentLine = <String>[];
      var currentLength = 0;
      var indent = lines.isNotEmpty ? subsequentIndent : initialIndent;
      var width = this.width - indent.length;

      if (dropWhitespace && chunks.last.trim() == '' && lines.isNotEmpty) {
        chunks.removeLast();
      }

      while (chunks.isNotEmpty) {
        var length = chunks.last.length;

        if (currentLength + length <= width) {
          currentLine.add(chunks.removeLast());
          currentLength += length;
        } else {
          break;
        }
      }

      if (chunks.isNotEmpty && chunks.last.length > width) {
        handleLongWord(chunks, currentLine, currentLength, width);
        currentLength = currentLine.fold<int>(0, (sum, line) => sum + line.length);
      }

      if (dropWhitespace && currentLine.isNotEmpty && currentLine.last.trim() == '') {
        final last = currentLine.removeLast();
        currentLength -= last.length;
      }

      if (currentLine.isNotEmpty) {
        if (maxLines == -1 ||
            lines.length + 1 < maxLines ||
            (chunks.isEmpty || dropWhitespace && chunks.length == 1 && chunks[0].trim() == '') && currentLength <= width) {
          lines.add(indent + currentLine.join());
        } else {
          var not = true;

          while (currentLine.isNotEmpty) {
            if (currentLine.last.trim().isNotEmpty && currentLength + placeholder.length <= width) {
              currentLine.add(placeholder);
              lines.add(indent + currentLine.join());
              not = false;
              break;
            }

            final last = currentLine.removeLast();
            currentLength -= last.length;
          }

          if (not) {
            if (lines.isNotEmpty) {
              final previousLine = lines.last.trimRight();

              if (previousLine.length + placeholder.length <= width) {
                lines[lines.length - 1] = previousLine + placeholder;
              }

              lines.add(indent + placeholder.trimLeft());
            }
          }

          break;
        }
      }
    }

    return lines;
  }

  @protected
  List<String> splitChunks(String text) {
    text = mungeWhiteSpace(text);
    return split(text);
  }

  List<String> wrap(String text) {
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

import 'package:meta/meta.dart';

@immutable
class Environment {
  const Environment({
    this.commentStart = '{#',
    this.commentEnd = '#}',
    this.variableStart = '{{',
    this.variableEnd = '}}',
    this.blockStart = '{%',
    this.blockEnd = '%}',
    this.lineCommentPrefix = '##',
    this.lineStatementPrefix = '#',
    this.lstripBlocks = false,
    this.trimBlocks = false,
    this.newlineSequence = const <String>['\r\n', '\r', '\n'],
    this.keepTrailingNewline = false,
  })  : assert(commentStart != commentEnd),
        assert(variableStart != variableEnd),
        assert(blockStart != variableEnd);

  final String commentStart;

  final String commentEnd;

  final String variableStart;

  final String variableEnd;

  final String blockStart;

  final String blockEnd;

  final String lineCommentPrefix;

  final String lineStatementPrefix;

  final bool lstripBlocks;

  final bool trimBlocks;

  final List<String> newlineSequence;

  final bool keepTrailingNewline;

  Environment change({
    String commentStart,
    String commentEnd,
    String variableStart,
    String variableEnd,
    String blockStart,
    String blockEnd,
    String lineCommentPrefix,
    String lineStatementPrefix,
    bool lstripBlocks,
    bool trimBlocks,
    List<String> newlineSequence,
    bool keepTrailingNewline,
  }) {
    return Environment(
      commentStart: commentStart ?? this.commentStart,
      commentEnd: commentEnd ?? this.commentEnd,
      variableStart: variableStart ?? this.variableStart,
      variableEnd: variableEnd ?? this.variableEnd,
      blockStart: blockStart ?? this.blockStart,
      blockEnd: blockEnd ?? this.blockEnd,
      lineCommentPrefix: lineCommentPrefix ?? this.lineCommentPrefix,
      lineStatementPrefix: lineStatementPrefix ?? this.lineStatementPrefix,
      lstripBlocks: lstripBlocks ?? this.lstripBlocks,
      trimBlocks: trimBlocks ?? this.trimBlocks,
      newlineSequence: newlineSequence ?? this.newlineSequence,
      keepTrailingNewline: keepTrailingNewline ?? this.keepTrailingNewline,
    );
  }
}

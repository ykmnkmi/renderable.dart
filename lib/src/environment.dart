import 'package:meta/meta.dart';

@immutable
class Environment {
  const Environment({
    this.commentBegin = '{#',
    this.commentEnd = '#}',
    this.variableBegin = '{{',
    this.variableEnd = '}}',
    this.blockBegin = '{%',
    this.blockEnd = '%}',
    this.lineCommentPrefix = '##',
    this.lineStatementPrefix = '#',
    this.lstripBlocks = false,
    this.trimBlocks = false,
    this.newlineSequence = const <String>['\r\n', '\r', '\n'],
    this.keepTrailingNewline = false,
  })  : assert(commentBegin != commentEnd),
        assert(variableBegin != variableEnd),
        assert(blockBegin != variableEnd);

  final String commentBegin;

  final String commentEnd;

  final String variableBegin;

  final String variableEnd;

  final String blockBegin;

  final String blockEnd;

  final String lineCommentPrefix;

  final String lineStatementPrefix;

  final bool lstripBlocks;

  final bool trimBlocks;

  final List<String> newlineSequence;

  final bool keepTrailingNewline;

  Environment change({
    String commentBegin,
    String commentEnd,
    String variableBegin,
    String variableEnd,
    String blockBegin,
    String blockEnd,
    String lineCommentPrefix,
    String lineStatementPrefix,
    bool lstripBlocks,
    bool trimBlocks,
    List<String> newlineSequence,
    bool keepTrailingNewline,
  }) {
    return Environment(
      commentBegin: commentBegin ?? this.commentBegin,
      commentEnd: commentEnd ?? this.commentEnd,
      variableBegin: variableBegin ?? this.variableBegin,
      variableEnd: variableEnd ?? this.variableEnd,
      blockBegin: blockBegin ?? this.blockBegin,
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

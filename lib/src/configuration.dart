import 'package:meta/meta.dart';

@immutable
class Configuration {
  const Configuration({
    this.commentBegin = '{#',
    this.commentEnd = '#}',
    this.variableBegin = '{{',
    this.variableEnd = '}}',
    this.blockBegin = '{%',
    this.blockEnd = '%}',
    this.lineCommentPrefix = '##',
    this.lineStatementPrefix = '#',
    this.lStripBlocks = false,
    this.trimBlocks = false,
    this.newLine = '\n',
    this.keepTrailingNewLine = false,
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

  final bool lStripBlocks;

  final bool trimBlocks;

  final String newLine;

  final bool keepTrailingNewLine;

  Configuration change({
    String? commentBegin,
    String? commentEnd,
    String? variableBegin,
    String? variableEnd,
    String? blockBegin,
    String? blockEnd,
    String? lineCommentPrefix,
    String? lineStatementPrefix,
    bool? lStripBlocks,
    bool? trimBlocks,
    String? newLine,
    bool? keepTrailingNewLine,
  }) {
    return Configuration(
      commentBegin: commentBegin ?? this.commentBegin,
      commentEnd: commentEnd ?? this.commentEnd,
      variableBegin: variableBegin ?? this.variableBegin,
      variableEnd: variableEnd ?? this.variableEnd,
      blockBegin: blockBegin ?? this.blockBegin,
      blockEnd: blockEnd ?? this.blockEnd,
      lineCommentPrefix: lineCommentPrefix ?? this.lineCommentPrefix,
      lineStatementPrefix: lineStatementPrefix ?? this.lineStatementPrefix,
      lStripBlocks: lStripBlocks ?? this.lStripBlocks,
      trimBlocks: trimBlocks ?? this.trimBlocks,
      newLine: newLine ?? this.newLine,
      keepTrailingNewLine: keepTrailingNewLine ?? this.keepTrailingNewLine,
    );
  }
}

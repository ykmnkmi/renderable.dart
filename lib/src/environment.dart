import 'package:meta/meta.dart';

@immutable
class Environment {
  const Environment(
      {this.commentStart = '{#',
      this.commentEnd = '#}',
      this.expressionStart = '{{',
      this.expressionEnd = '}}',
      this.statementStart = '{%',
      this.statementEnd = '%}'})
      : assert(commentStart != commentEnd),
        assert(expressionStart != expressionEnd),
        assert(statementStart != expressionEnd);

  final String commentStart;

  final String commentEnd;

  final String expressionStart;

  final String expressionEnd;

  final String statementStart;

  final String statementEnd;

  Environment change(
      {String commentStart,
      String commentEnd,
      String expressionStart,
      String expressionEnd,
      String statementStart,
      String statementEnd}) {
    return Environment(
      commentStart: commentStart ?? this.commentStart,
      commentEnd: commentEnd ?? this.commentEnd,
      expressionStart: expressionStart ?? this.expressionStart,
      expressionEnd: expressionEnd ?? this.expressionEnd,
      statementStart: statementStart ?? this.statementStart,
      statementEnd: statementEnd ?? this.statementEnd,
    );
  }
}

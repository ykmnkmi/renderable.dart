import 'package:meta/meta.dart';

@immutable
class Environment {
  static const Environment default_ = Environment();

  final String commentStart;

  final String commentEnd;

  final String expressionStart;

  final String expressionEnd;

  final String statementStart;

  final String statementEnd;

  const Environment({
    this.commentStart = '{#',
    this.commentEnd = '#}',
    this.expressionStart = '{{',
    this.expressionEnd = '}}',
    this.statementStart = '{%',
    this.statementEnd = '%}',
  })  : assert(commentStart != expressionStart),
        assert(expressionStart != statementStart),
        assert(statementStart != commentStart);
}

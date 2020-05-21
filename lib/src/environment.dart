import 'package:meta/meta.dart';

import 'mirror.dart' as mirror;

typedef FieldGetter = Object? Function(String field, Object? object);

@immutable
class Environment {
  final String commentStart;

  final String commentEnd;

  final String expressionStart;

  final String expressionEnd;

  final String statementStart;

  final String statementEnd;

  final FieldGetter getField;

  const Environment({
    this.commentStart = '{#',
    this.commentEnd = '#}',
    this.expressionStart = '{{',
    this.expressionEnd = '}}',
    this.statementStart = '{%',
    this.statementEnd = '%}',
    this.getField = mirror.getField,
  })  : assert(commentStart != expressionStart),
        assert(expressionStart != statementStart),
        assert(statementStart != commentStart);
}

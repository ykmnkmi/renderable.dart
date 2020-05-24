import 'package:meta/meta.dart';

import 'default.dart' as d;

typedef FieldGetter = Object Function(String field, Object object);

typedef Finalizer = Object Function(Object value);

@immutable
class Environment {
  final String commentStart;

  final String commentEnd;

  final String expressionStart;

  final String expressionEnd;

  final String statementStart;

  final String statementEnd;

  final FieldGetter getField;

  final Finalizer finalize;

  const Environment({
    this.commentStart = '{#',
    this.commentEnd = '#}',
    this.expressionStart = '{{',
    this.expressionEnd = '}}',
    this.statementStart = '{%',
    this.statementEnd = '%}',
    this.getField = d.getField,
    this.finalize = d.finalizer,
  })  : assert(commentStart != expressionStart),
        assert(expressionStart != statementStart),
        assert(statementStart != commentStart);
}

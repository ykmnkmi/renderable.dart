import 'package:meta/meta.dart';

import 'default.dart' as $default;

typedef ItemGetter = Object Function(Map<String, Object> map, String key);

typedef FieldGetter = Object Function(Object object, String field);

typedef Finalizer = Object Function(Object value);

@immutable
class Environment {
  const Environment({
    this.commentStart = '{#',
    this.commentEnd = '#}',
    this.expressionStart = '{{',
    this.expressionEnd = '}}',
    this.statementStart = '{%',
    this.statementEnd = '%}',
    this.getItem = $default.getItem,
    this.getField = $default.getField,
    this.finalize = $default.finalizer,
  })  : assert(commentStart != commentEnd),
        assert(expressionStart != expressionEnd),
        assert(statementStart != expressionEnd);

  final String commentStart;

  final String commentEnd;

  final String expressionStart;

  final String expressionEnd;

  final String statementStart;

  final String statementEnd;

  final ItemGetter getItem;

  final FieldGetter getField;

  final Finalizer finalize;

  Environment change(
    String commentStart,
    String commentEnd,
    String expressionStart,
    String expressionEnd,
    String statementStart,
    String statementEnd,
    FieldGetter getField,
    Finalizer finalize,
  ) {
    return Environment(
      commentStart: commentStart ?? this.commentStart,
      commentEnd: commentEnd ?? this.commentEnd,
      expressionStart: expressionStart ?? this.expressionStart,
      expressionEnd: expressionEnd ?? this.expressionEnd,
      statementStart: statementStart ?? this.statementStart,
      statementEnd: statementEnd ?? this.statementEnd,
      getField: getField ?? this.getField,
      finalize: finalize ?? this.finalize,
    );
  }
}

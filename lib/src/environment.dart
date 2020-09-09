import 'package:meta/meta.dart';

import 'util.dart';

typedef ItemGetter = Object Function(Map<String, Object> map, String key);

Object defaultGetItem(Map<String, Object> map, String key) {
  return map[key];
}

typedef FieldGetter = Object Function(Object object, String field);

Object defaultGetField(Object instance, String field) {
  throw UnimplementedError();
}

typedef Finalizer = Object Function(Object value);

Object defaultFinalizer(Object value) {
  value ??= '';

  if (value is String) {
    return value;
  }

  return repr(value, false);
}

@immutable
class Environment {
  const Environment({
    this.commentStart = '{#',
    this.commentEnd = '#}',
    this.expressionStart = '{{',
    this.expressionEnd = '}}',
    this.statementStart = '{%',
    this.statementEnd = '%}',
    this.getItem = defaultGetItem,
    this.getField = defaultGetField,
    this.finalize = defaultFinalizer,
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

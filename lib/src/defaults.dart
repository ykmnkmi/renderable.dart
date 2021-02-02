import 'package:renderable/src/runtime.dart';

import 'utils.dart';

export 'filters.dart' show filters, environmentFilters;
export 'tests.dart' show tests;

const String blockBegin = '{%';
const String blockEnd = '%}';
const String variableBegin = '{{';
const String variableEnd = '}}';
const String commentBegin = '{#';
const String commentEnd = '#}';
const String? lineCommentPrefix = null;
const String? lineStatementPrefix = null;
const bool trimBlocks = false;
const bool lStripBlocks = false;
const String newLine = '\n';
const bool keepTrailingNewLine = false;

const Map<String, Object?> globals = <String, Object?>{
  'namespace': Namespace.factory,
  'list': list,
  'range': range,
};

Object? apply(Object object, List<Object?> positional, [Map<Symbol, Object?> named = const <Symbol, Object?>{}]) {
  return object.noSuchMethod(Invocation.genericMethod(#call, null, positional, named));
}

Object? finalize(Object? value) {
  return value;
}

Object? getField(Object? object, String field) {
  throw NoSuchMethodError.withInvocation(object, Invocation.getter(Symbol(field)));
}

Undefined undefined({String? hint, Object? object, String? name}) {
  return Undefined(hint: hint, object: object, name: name);
}

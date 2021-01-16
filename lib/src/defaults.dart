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

const Map<String, dynamic> globals = {
  'namespace': Namespace.factory,
  'range': range,
};

dynamic finalize(dynamic value) {
  if (value == null) {
    return '';
  }

  if (value is String) {
    return value;
  }

  return value;
}

dynamic getField(dynamic object, String field) {
  throw NoSuchMethodError.withInvocation(object, Invocation.getter(Symbol(field)));
}

dynamic callCallable(dynamic object, List<dynamic> positional, [Map<Symbol, dynamic> named = const {}]) {
  return object.noSuchMethod(Invocation.genericMethod(#call, null, positional, named));
}

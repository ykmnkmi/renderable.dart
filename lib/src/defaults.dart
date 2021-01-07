import 'utils.dart';

export 'filters.dart' show filters, contextFilters, environmentFilters;
export 'tests.dart' show tests;

const String blockBegin = '{%';
const String blockEnd = '%}';
const String variableBegin = '{{';
const String variableEnd = '}}';
const String commentBegin = '{#';
const String commentEnd = '#}';
const String lineCommentPrefix = '##';
const String lineStatementPrefix = '#';
const bool trimBlocks = false;
const bool lStripBlocks = false;
const String newLine = '\n';
const bool keepTrailingNewLine = false;

const Map<String, dynamic> globals = <String, dynamic>{
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

dynamic callCallable(dynamic object, List<dynamic> positional, [Map<Symbol, dynamic> named = const <Symbol, dynamic>{}]) {
  return object.noSuchMethod(Invocation.genericMethod(#call, null, positional, named));
}

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

dynamic finalizer([dynamic value]) {
  if (value == null) {
    return '';
  }

  if (value is String) {
    return value;
  }

  return represent(value);
}

const Map<String, dynamic> globals = <String, dynamic>{
  'range': range,
};

dynamic getAttribute(dynamic object, String field) {
  return null;
}

dynamic getItem(dynamic object, dynamic key) {
  if (key is Iterable<int> Function(int) && object is Iterable) {
    return slice(object.toList(), key);
  }

  return object[key];
}

Iterable<dynamic> slice(List<dynamic> list, Iterable<int> Function(int) indices) sync* {
  for (final i in indices(list.length)) {
    yield list[i];
  }
}

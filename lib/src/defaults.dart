import 'utils.dart';

export 'filters.dart' show filters;
export 'tests.dart' show tests;

const blockBegin = '{%';
const blockEnd = '%}';
const variableBegin = '{{';
const variableEnd = '}}';
const commentBegin = '{#';
const commentEnd = '#}';
const lineCommentPrefix = '##';
const lineStatementPrefix = '#';
const trimBlocks = false;
const lStripBlocks = false;
const newLine = '\n';
const keepTrailingNewLine = false;

dynamic finalizer([dynamic value]) {
  if (value == null) {
    return '';
  }

  if (value is String) {
    return value;
  }

  return represent(value);
}

const globals = <String, dynamic>{
  'range': range,
};

dynamic attributeGetter(dynamic object, String field) {
  return null;
}

dynamic itemGetter(dynamic object, dynamic key) {
  try {
    return object[key];
  } catch (e) {
    return null;
  }
}

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

Object? finalizer([Object? value]) {
  if (value == null) {
    return '';
  }

  if (value is String) {
    return value;
  }

  return represent(value);
}

Object? itemGetter(Object? object, Object? key) {
  try {
    return unsafeCast<dynamic>(object)[key];
  } catch (e) {
    return null;
  }
}

const globals = <String, Object>{};

import 'package:renderable/src/utils.dart';

class _ContextFilter {
  const _ContextFilter();
}

class _EnvironmentFilter {
  const _EnvironmentFilter();
}

const contextFilter = _ContextFilter();

const environmentFilter = _EnvironmentFilter();

int count(Object? value) {
  return unsafeCast<dynamic>(value).length;
}

List<Object?> list(Object? value) {
  if (value is String) {
    return value.split('');
  }

  if (value is Iterable<Object?>) {
    return value.toList();
  }

  if (value is Map<Object?, Object?>) {
    return value.keys.toList();
  }

  return unsafeCast<dynamic>(value).toList();
}

String lower(Object? value) {
  if (value is String) {
    return value.toLowerCase();
  }

  return value.toString().toLowerCase();
}

String string(Object? value) {
  return value.toString();
}

String upper(Object? value) {
  if (value is String) {
    return value.toUpperCase();
  }

  return value.toString().toUpperCase();
}

const filters = <String, Function>{
  'count': count,
  'length': count,
  'list': list,
  'lower': lower,
  'string': string,
  'upper': upper,
  // 'abs': doAbs,
  // 'attr': doAttr,
  // 'batch': doBatch,
  // 'capitalize': doCapitalize,
  // 'center': doCenter,
  // 'd': doDefault,
  // 'default': doDefault,
  // 'e': doEscape,
  // 'escape': doEscape,
  // 'filesizeformat': doFileSizeFormat,
  // 'first': doFirst,
  // 'float': doFloat,
  // 'forceescape': doForceEscape,
  // 'int': doInt,
  // 'join': doJoin,
  // 'last': doLast,
  // 'random': doRandom,
  // 'sum': doSum,
  // 'trim': doTrim,

  // 'dictsort': doDictSort,
  // 'format': doFormat,
  // 'groupby': doGroupBy,
  // 'indent': doIndent,
  // 'map': doMap,
  // 'max': doMax,
  // 'min': doMin,
  // 'pprint': doPPrint,
  // 'reject': doReject,
  // 'rejectattr': doRejectAttr,
  // 'replace': doReplace,
  // 'reverse': doReverse,
  // 'round': doRound,
  // 'safe': doMarkSafe,
  // 'select': doSelect,
  // 'selectattr': doSelectAttr,
  // 'slice': doSlice,
  // 'sort': doSort,
  // 'striptags': doStripTags,
  // 'title': doTitle,
  // 'tojson': doToJson,
  // 'truncate': doTruncate,
  // 'unique': doUnique,
  // 'urlencode': doURLEncode,
  // 'urlize': doURLize,
  // 'wordcount': doWordCount,
  // 'wordwrap': doWordwrap,
  // 'xmlattr': doXMLAttr,
};

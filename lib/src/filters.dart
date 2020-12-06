class _ContextFilter {
  const _ContextFilter();
}

class _EnvironmentFilter {
  const _EnvironmentFilter();
}

const contextFilter = _ContextFilter();

const environmentFilter = _EnvironmentFilter();

String string(Object? value) {
  if (value == null) {
    return '';
  }

  if (value is String) {
    return value;
  }

  return value.toString();
}

const filters = <String, Function>{
  'string': string,
  // 'abs': doAbs,
  // 'attr': doAttr,
  // 'batch': doBatch,
  // 'capitalize': doCapitalize,
  // 'center': doCenter,
  // 'count': doCount,
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
  // 'length': doCount,
  // 'list': doList,
  // 'lower': doLower,
  // 'random': doRandom,
  // 'sum': doSum,
  // 'trim': doTrim,
  // 'upper': doUpper,

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

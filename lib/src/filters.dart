import 'dart:math' as math;

import 'enirvonment.dart';
import 'markup.dart' show Markup;
import 'utils.dart' as utils;

const List<List<String>> suffixes = [
  [' KiB', ' kB'],
  [' MiB', ' MB'],
  [' GiB', ' GB'],
  [' TiB', ' TB'],
  [' PiB', ' PB'],
  [' EiB', ' EB'],
  [' ZiB', ' ZB'],
  [' YiB', ' YB'],
];

List<String> prepareAttributeParts(String attribute) {
  return attribute.split('.');
}

dynamic Function(dynamic) makeAttributeGetter(Environment environment, String attributeOrAttributes,
    {dynamic Function(dynamic)? postProcess, dynamic defaultValue}) {
  final attributes = prepareAttributeParts(attributeOrAttributes);

  dynamic attributeGetter(dynamic item) {
    for (final part in attributes) {
      item = doAttribute(environment, item, part);

      if (item == null) {
        if (defaultValue != null) {
          item = defaultValue;
        }

        break;
      }
    }

    if (postProcess != null) {
      item = postProcess(item);
    }

    return item;
  }

  return attributeGetter;
}

num doAbs(num number) {
  return number.abs();
}

dynamic doAttribute(Environment environment, dynamic object, String attribute) {
  return environment.getAttribute(object, attribute);
}

Iterable<List<dynamic>> doBatch(Iterable<dynamic> items, int lineCount, [dynamic fillWith]) sync* {
  var temp = <dynamic>[];

  for (final item in items) {
    if (temp.length == lineCount) {
      yield temp;
      temp = <dynamic>[];
    }

    temp.add(item);
  }

  if (temp.isNotEmpty) {
    if (fillWith != null) {
      temp.addAll(List<dynamic>.filled(lineCount - temp.length, fillWith));
    }

    yield temp;
  }
}

String doCapitalize(String string) {
  if (string.length == 1) {
    return string.toUpperCase();
  }

  return string.substring(0, 1).toUpperCase() + string.substring(1).toLowerCase();
}

String doCenter(String string, int width) {
  if (string.length >= width) {
    return string;
  }

  final padLength = (width - string.length) ~/ 2;
  final pad = ' ' * padLength;
  return pad + string + pad;
}

int doLength(dynamic items) {
  return items.length as int;
}

dynamic doDefault(dynamic value, [dynamic defaultValue = '', bool boolean = false]) {
  if (boolean) {
    return utils.boolean(value) ? value : defaultValue;
  }

  return value ?? defaultValue;
}

Markup doEscape(dynamic value) {
  if (value is Markup) {
    return value;
  }

  return Markup.escape(value.toString());
}

String doFileSizeFormat(dynamic value, [bool binary = false]) {
  final base = binary ? 1024 : 1000;

  double bytes;

  if (value is num) {
    bytes = value.toDouble();
  } else if (value is String) {
    bytes = double.parse(value);
  } else {
    throw TypeError();
  }

  if (bytes == 1.0) {
    return '1 Byte';
  } else if (bytes < base) {
    const suffix = ' Bytes';
    final size = bytes.toStringAsFixed(1);

    if (size.endsWith('.0')) {
      return size.substring(0, size.length - 2) + suffix;
    }

    return size + suffix;
  } else {
    final k = binary ? 0 : 1;
    late num unit;

    for (var i = 0; i < suffixes.length; i++) {
      unit = math.pow(base, i + 2);

      if (bytes < unit) {
        return (base * bytes / unit).toStringAsFixed(1) + suffixes[i][k];
      }
    }

    return (base * bytes / unit).toStringAsFixed(1) + suffixes.last[k];
  }
}

dynamic doFirst(Iterable<dynamic> values) {
  return values.first;
}

double doFloat(dynamic value, {double default_ = 0.0}) {
  if (value is String) {
    try {
      return double.parse(value);
    } on FormatException {
      return default_;
    }
  }

  try {
    return value.toDouble() as double;
  } catch (e) {
    return default_;
  }
}

Markup doForceEscape(dynamic value) {
  return Markup.escape(value.toString());
}

int doInteger(dynamic value, {int default_ = 0, int base = 10}) {
  if (value is String) {
    if (base == 16 && value.startsWith('0x')) {
      value = value.substring(2);
    }

    try {
      return int.parse(value, radix: base);
    } on FormatException {
      if (base == 10) {
        try {
          return double.parse(value).toInt();
        } on FormatException {
          // pass
        }
      }
    }
  }

  try {
    return value.toInt() as int;
  } catch (e) {
    return default_;
  }
}

String doJoin(Environment environment, Iterable<dynamic> items, [String delimiter = '', String? attribute]) {
  if (attribute != null) {
    return items.map<dynamic>(makeAttributeGetter(environment, attribute)).join(delimiter);
  }

  return items.join(delimiter);
}

dynamic doLast(Iterable<dynamic> values) {
  return values.last;
}

String doLower(String string) {
  return string.toLowerCase();
}

String doPPrint(dynamic object) {
  return utils.format(object);
}

dynamic doRandom(Environment environment, dynamic values) {
  final length = values.length as int;
  final index = environment.random.nextInt(length);
  return values[index];
}

String doString(dynamic value) {
  return value.toString();
}

num doSum(Environment environment, Iterable<dynamic> values, {String? attribute, num start = 0}) {
  if (attribute != null) {
    values = values.map<dynamic>(makeAttributeGetter(environment, attribute));
  }

  return values.cast<num>().fold(start, (s, n) => s + n);
}

String doTrim(String value) {
  return value.trim();
}

String doUpper(String string) {
  return string.toUpperCase();
}

const Map<String, Function> filters = {
  'abs': doAbs,
  'attr': doAttribute,
  'batch': doBatch,
  'capitalize': doCapitalize,
  'center': doCenter,
  'count': doLength,
  'd': doDefault,
  'default': doDefault,
  'e': doEscape,
  'escape': doEscape,
  'filesizeformat': doFileSizeFormat,
  'first': doFirst,
  'float': doFloat,
  'forceescape': doForceEscape,
  'int': doInteger,
  'join': doJoin,
  'last': doLast,
  'length': doLength,
  'list': utils.list,
  'lower': doLower,
  'pprint': doPPrint,
  'random': doRandom,
  'string': doString,
  'sum': doSum,
  'trim': doTrim,
  'upper': doUpper,

  // 'dictsort': doDictSort,
  // 'format': doFormat,
  // 'groupby': doGroupBy,
  // 'indent': doIndent,
  // 'map': doMap,
  // 'max': doMax,
  // 'min': doMin,
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

const Set<String> environmentFilters = {'attr', 'join', 'random', 'sum'};

library filters;

import 'dart:convert';
import 'dart:math' as math;

import 'package:textwrap/textwrap.dart';

import 'enirvonment.dart';
import 'exceptions.dart';
import 'markup.dart';
import 'runtime.dart';
import 'utils.dart';

List<String> prepareAttributeParts(String attribute) {
  return attribute.split('.');
}

Object? Function(Object?) makeAttributeGetter(Environment environment, String attributeOrAttributes,
    {Object? Function(Object?)? postProcess, Object? defaultValue}) {
  final attributes = prepareAttributeParts(attributeOrAttributes);

  Object? attributeGetter(Object? item) {
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

Object? doAttribute(Environment environment, Object? object, String attribute) {
  return environment.getAttribute(object, attribute);
}

Iterable<List<Object?>> doBatch(Iterable<Object?> items, int lineCount, [Object? fillWith]) sync* {
  var temp = <Object?>[];

  for (final item in items) {
    if (temp.length == lineCount) {
      yield temp;
      temp = <Object?>[];
    }

    temp.add(item);
  }

  if (temp.isNotEmpty) {
    if (fillWith != null) {
      temp.addAll(List<Object?>.filled(lineCount - temp.length, fillWith));
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

int doLength(Object? items) {
  return (items as dynamic).length as int;
}

Object? doDefault(Object? value, [Object? defaultValue = '', bool asBoolean = false]) {
  if (value is Undefined || (asBoolean && !boolean(value))) {
    return defaultValue;
  }

  return value;
}

Markup doEscape(Object? value) {
  if (value is Markup) {
    return value;
  }

  return Markup(value as String);
}

String doFileSizeFormat(Object? value, [bool binary = false]) {
  const suffixes = <List<String>>[
    [' KiB', ' kB'],
    [' MiB', ' MB'],
    [' GiB', ' GB'],
    [' TiB', ' TB'],
    [' PiB', ' PB'],
    [' EiB', ' EB'],
    [' ZiB', ' ZB'],
    [' YiB', ' YB'],
  ];

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

Object? doFirst(Iterable<Object?> values) {
  return values.first;
}

double doFloat(Object? value, {double d = 0.0}) {
  if (value is String) {
    try {
      return double.parse(value);
    } on FormatException {
      return d;
    }
  }

  try {
    return (value as dynamic).toDouble() as double;
  } catch (e) {
    return d;
  }
}

Markup doForceEscape(Object? value) {
  return Markup(value.toString());
}

int doInteger(Object? value, {int d = 0, int base = 10}) {
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
    return (value as dynamic).toInt() as int;
  } catch (e) {
    return d;
  }
}

Object? doJoin(Context context, Iterable<Object?> values, [String delimiter = '', String? attribute]) {
  if (attribute != null) {
    values = values.map<Object?>(makeAttributeGetter(context.environment, attribute));
  }

  if (!boolean(context.get('autoescape'))) {
    return values.join(delimiter);
  }

  return context.escaped(values.map<Object?>((value) => context.escape(value)).join(delimiter));
}

Object? doLast(Iterable<Object?> values) {
  return values.last;
}

String doLower(String string) {
  return string.toLowerCase();
}

String doPPrint(Object? object) {
  return format(object);
}

Object? doRandom(Environment environment, Object? values) {
  final length = (values as dynamic).length as int;
  final index = environment.random.nextInt(length);
  return values[index];
}

Object? doReplace(Object? object, String from, String to, [int? count]) {
  late String string;
  late bool isNotMarkup;

  if (object is String) {
    string = object;
    isNotMarkup = true;
  } else if (object is Markup) {
    string = object.toString();
    isNotMarkup = false;
  } else {
    string = object.toString();
    isNotMarkup = true;
  }

  if (count == null) {
    string = string.replaceAll(from, to);
  } else {
    while (count > 0) {
      string = string.replaceAll(from, to);
    }
  }

  return isNotMarkup ? string : Markup(string);
}

Object? doReverse(Object? value) {
  try {
    final values = list(value);
    return values.reversed;
  } catch (e) {
    throw FilterArgumentError('argument must be iterable');
  }
}

Markup doMarkSafe(String value) {
  return Markup.escaped(value);
}

String doString(Object? value) {
  return value.toString();
}

num doSum(Environment environment, Iterable<Object?> values, {String? attribute, num start = 0}) {
  if (attribute != null) {
    values = values.map<Object?>(makeAttributeGetter(environment, attribute));
  }

  return values.cast<num>().fold(start, (s, n) => s + n);
}

String doTrim(String value) {
  return value.trim();
}

String doUpper(String value) {
  return value.toUpperCase();
}

int doWordCount(String string) {
  final matches = RegExp(r'\w+').allMatches(string);
  return matches.length;
}

String doWordWrap(Environment environment, String string, int width, {bool breakLongWords = true, String? wrapString, bool breakOnHyphens = true}) {
  final wrapper = TextWrapper(width: width, expandTabs: false, replaceWhitespace: false, breakLongWords: breakLongWords, breakOnHyphens: breakOnHyphens);
  wrapString ??= environment.newLine;
  return const LineSplitter().convert(string).map<String>((line) => wrapper.wrap(line).join(wrapString!)).join(wrapString);
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
  'list': list,
  'lower': doLower,
  'pprint': doPPrint,
  'random': doRandom,
  'replace': doReplace,
  'reverse': doReverse,
  'safe': doMarkSafe,
  'string': doString,
  'sum': doSum,
  'trim': doTrim,
  'upper': doUpper,
  'wordcount': doWordCount,
  'wordwrap': doWordWrap,

  // 'dictsort': doDictSort,
  // 'format': doFormat,
  // 'groupby': doGroupBy,
  // 'indent': doIndent,
  // 'map': doMap,
  // 'max': doMax,
  // 'min': doMin,
  // 'reject': doReject,
  // 'rejectattr': doRejectAttr,
  // 'round': doRound,
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
  // 'xmlattr': doXMLAttr,
};

const Set<String> contextFilters = {'join'};

const Set<String> environmentFilters = {'attr', 'random', 'sum', 'wordwrap'};

import 'dart:math' as math;

import 'enirvonment.dart';
import 'markup.dart' show Markup;
import 'utils.dart' as utils;

const List<List<String>> _suffixes = <List<String>>[
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
      item = attribute(environment, item, part);

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

num abs(num number) {
  return number.abs();
}

dynamic attribute(Environment environment, dynamic object, String attribute) {
  return environment.getAttribute(object, attribute);
}

Iterable<List<dynamic>> batch(Iterable<dynamic> items, int lineCount, [dynamic fillWith]) sync* {
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

String capitalize(String string) {
  if (string.length == 1) {
    return string.toUpperCase();
  }

  return string.substring(0, 1).toUpperCase() + string.substring(1).toLowerCase();
}

String center(String string, int width) {
  if (string.length >= width) {
    return string;
  }

  final padLength = (width - string.length) ~/ 2;
  final pad = ' ' * padLength;
  return pad + string + pad;
}

int count(dynamic items) {
  return items.length as int;
}

dynamic defaultValue(dynamic value, [dynamic defaultValue = '', bool boolean = false]) {
  if (boolean) {
    return utils.boolean(value) ? value : defaultValue;
  }

  return value ?? defaultValue;
}

Markup escape(dynamic value) {
  if (value is Markup) {
    return value;
  }

  return Markup.escape(value.toString());
}

String fileSizeFormat(dynamic value, [bool binary = false]) {
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

    for (var i = 0; i < _suffixes.length; i++) {
      unit = math.pow(base, i + 2);

      if (bytes < unit) {
        return (base * bytes / unit).toStringAsFixed(1) + _suffixes[i][k];
      }
    }

    return (base * bytes / unit).toStringAsFixed(1) + _suffixes.last[k];
  }
}

dynamic first(Iterable<dynamic> values) {
  return values.first;
}

double float(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) {
    return defaultValue;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    try {
      return double.parse(value);
    } on FormatException {
      return defaultValue;
    }
  }

  return defaultValue;
}

Markup forceEscape(dynamic value) {
  return Markup.escape(value.toString());
}

int integer(dynamic value, [int defaultValue = 0, int radix = 10]) {
  if (value == null) {
    return defaultValue;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    try {
      return int.parse(value, radix: radix);
    } on FormatException {
      return defaultValue;
    }
  }

  return defaultValue;
}

String join(Environment environment, Iterable<dynamic> items, [String delimiter = '', String? attribute]) {
  if (attribute != null) {
    return items.map<dynamic>(makeAttributeGetter(environment, attribute)).join(delimiter);
  }

  return items.join(delimiter);
}

dynamic last(Iterable<dynamic> values) {
  return values.last;
}

String lower(String string) {
  return string.toLowerCase();
}

dynamic random(Environment environment, List<dynamic> values) {
  final length = values.length;
  return values[environment.random.nextInt(length)];
}

String string(dynamic value) {
  return value.toString();
}

num sum(Environment environment, Iterable<dynamic> values, {String? attribute, num start = 0}) {
  if (attribute != null) {
    values = values.map<dynamic>(makeAttributeGetter(environment, attribute));
  }

  return values.cast<num>().fold(start, (s, n) => s + n);
}

String trim(String value) {
  return value.trim();
}

String upper(String string) {
  return string.toUpperCase();
}

const Map<String, Function> filters = <String, Function>{
  'abs': abs,
  'attr': attribute,
  'batch': batch,
  'capitalize': capitalize,
  'center': center,
  'count': count,
  'd': defaultValue,
  'default': defaultValue,
  'e': escape,
  'escape': escape,
  'filesizeformat': fileSizeFormat,
  'first': first,
  'float': float,
  'forceescape': forceEscape,
  'int': integer,
  'join': join,
  'last': last,
  'length': count,
  'list': utils.list,
  'lower': lower,
  'random': random,
  'string': string,
  'sum': sum,
  'trim': trim,
  'upper': upper,

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

const Set<String> environmentFilters = <String>{'attr', 'join', 'random'};

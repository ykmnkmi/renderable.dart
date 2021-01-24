library utils;

import 'runtime.dart';

// import 'package:dart_style/dart_style.dart';

typedef Indices = Iterable<int> Function(int stopOrStart, [int? stop, int? step]);

bool boolean(Object? value) {
  if (value == null || value is Undefined) {
    return false;
  }

  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0.0;
  }

  if (value is String) {
    return value.isNotEmpty;
  }

  if (value is Iterable) {
    return value.isNotEmpty;
  }

  if (value is Map) {
    return value.isNotEmpty;
  }

  return true;
}

String format(dynamic object) {
  final source = represent(object);
  return source;
  // return DartFormatter().formatStatement(source);
}

List<dynamic> list(dynamic iterable) {
  if (iterable is List) {
    return iterable;
  }

  if (iterable is Iterable) {
    return iterable.toList();
  }

  if (iterable is String) {
    return iterable.split('');
  }

  if (iterable is Map) {
    return iterable.keys.toList();
  }

  return iterable.toList() as List<dynamic>;
}

Iterable<int> range(int stopOrStart, [int? stop, int step = 1]) sync* {
  if (step == 0) {
    throw StateError('range() argument 3 must not be zero');
  }

  int start;

  if (stop == null) {
    start = 0;
    stop = stopOrStart;
  } else {
    start = stopOrStart;
    stop = stop;
  }

  if (step > 0) {
    for (var i = start; i < stop; i += step) {
      yield i;
    }
  } else {
    for (var i = start; i > stop; i += step) {
      yield i;
    }
  }
}

String represent(Object? object) {
  if (object is Iterable<Object?>) {
    final buffer = StringBuffer('[')
      ..writeAll(object.map<String>(represent), ', ')
      ..write(']');
    return buffer.toString();
  } else if (object is Map<Object?, Object?>) {
    final buffer = StringBuffer('{');
    final pairs = <Object>[];

    object.forEach((key, value) {
      pairs.add('${represent(key)}: ${represent(value)}');
    });

    buffer
      ..writeAll(pairs, ', ')
      ..write('}');
    return buffer.toString();
  } else if (object is String) {
    final string = object.replaceAll('\'', r"\'").replaceAll('\r', r'\\r').replaceAll('\n', r'\\n');
    return "'$string'";
  } else {
    return object.toString();
  }
}

List<T> slice<T>(List<T> list, Indices indices) {
  final result = <T>[];

  for (final i in indices(list.length)) {
    result.add(list[i]);
  }

  return result;
}

String sliceString(String string, Indices indices) {
  final buffer = StringBuffer();

  for (final i in indices(string.length)) {
    buffer.write(string[i]);
  }

  return buffer.toString();
}

// @pragma('vm:prefer-inline')
// T unsafeCast<T>(dynamic object) {
//   // ignore: return_of_invalid_type
//   return object;
// }

class Cycler extends Iterable<dynamic> {
  Cycler(List<dynamic> values)
      : values = List<dynamic>.of(values),
        length = values.length,
        index = 0;

  final List<dynamic> values;

  @override
  final int length;

  int index;

  dynamic get current {
    return values[index];
  }

  @override
  Iterator<dynamic> get iterator {
    return CyclerIterator(this);
  }

  dynamic next() {
    final result = current;
    index = (index + 1) % length;
    return result;
  }

  void reset() {
    index = 0;
  }
}

class CyclerIterator extends Iterator<dynamic> {
  CyclerIterator(this.cycler);

  final Cycler cycler;

  dynamic last;

  @override
  dynamic get current {
    return last;
  }

  @override
  bool moveNext() {
    last = cycler.next();
    return true;
  }
}

bool boolean(Object? value) {
  if (value == null) {
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

Iterable<int> range(int n) sync* {
  for (var i = 0; i < n; i++) {
    yield i;
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
    final string = object.replaceAll('\'', '\\\'');
    return "'$string'";
  } else {
    return object.toString();
  }
}

T safe<T>(T arg, T Function(T arg) fn) {
  try {
    return fn(arg);
  } catch (e) {
    return arg;
  }
}

dynamic slice(dynamic list, int start, int stop, [int step = 1]) {
  var valid = false;

  if (step > 0 && start < stop) {
    valid = true;
  } else if (step < 0 && start > stop) {
    valid = true;
  }

  if (list is String) {
    return valid ? _sliceString(list, start, stop, step) : '';
  }

  return valid ? _slice(list, start, stop, step) : <dynamic>[];
}

List<dynamic> _slice(dynamic list, int start, int stop, int step) {
  final result = <dynamic>[];

  if (step > 0) {
    for (var i = start; i < stop; i += step) {
      result.add(list[i]);
    }
  } else {
    for (var i = start; i > stop; i += step) {
      result.add(list[i]);
    }
  }

  return result;
}

String _sliceString(String string, int start, int stop, int step) {
  final buffer = StringBuffer();

  if (step > 0) {
    for (var i = start; i < stop; i += step) {
      buffer.write(string[i]);
    }
  } else {
    for (var i = start; i > stop; i += step) {
      buffer.write(string[i]);
    }
  }

  return buffer.toString();
}

// @tryInline
// @pragma('vm:prefer-inline')
// T unsafeCast<T>(dynamic object) {
//   // ignore: return_of_invalid_type
//   return object;
// }

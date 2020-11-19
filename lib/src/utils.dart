List<Object> slice(List<Object> list, int start, [int end, int step]) {
  final result = <Object>[];
  final length = list.length;

  end ??= length;
  step ??= 1;

  if (start < 0) {
    start = length + start;
  }

  if (end < 0) {
    end = length + end;
  }

  if (step > 0) {
    for (var i = start; i < end; i += step) {
      result.add(list[i]);
    }
  } else {
    step = -step;

    for (var i = end - 1; i >= start; i -= step) {
      result.add(list[i]);
    }
  }

  return list;
}

String repr(Object object) {
  if (object is Iterable<Object>) {
    final buffer = StringBuffer('[')
      ..writeAll(object.map<String>(repr), ', ')
      ..write(']');
    return buffer.toString();
  } else if (object is Map<Object, Object>) {
    final buffer = StringBuffer('{');
    final pairs = <Object>[];

    object.forEach((key, value) {
      pairs.add('${repr(key)}: ${repr(value)}');
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
